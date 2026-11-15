/* Legacy qs data reader, derived from qs 0.27.3 format/decoding code.
 * Copyright (C) 2019-present Travers Ching; DataIO adaptations 2026.
 * GPL-3; see inst/LICENSES/GPL-3.txt and the codec notices. Codec sources are unmodified.
 * R 4.6 removed qs's internal object APIs. Only ordinary matrix data is
 * reconstructed here, using supported R APIs; no subprocess or disk writes.
 */
#include <Rcpp.h>
#include <algorithm>
#include <array>
#include <climits>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <limits>
#include <memory>
#include <string>
#include <vector>
#include "vendor/ZSTD/zstd.h"
#include "vendor/LZ4/lz4.h"
#include "vendor/xxhash/xxhash.h"
#include "vendor/BLOSC/unshuffle_routines.h"

namespace {
constexpr size_t block_size = 524288;

void fail(const char* text) { throw std::runtime_error(text); }

class Input {
  std::ifstream file;
  uint64_t position = 0, end = 0, recorded_length = 0;
  uint64_t blocks = 0, decoded_bytes = 0;
  uint32_t recorded_hash = 0;
  bool has_hash = false;
  unsigned algorithm = 0;
  std::vector<unsigned char> decoded = std::vector<unsigned char>(block_size);
  std::vector<unsigned char> compressed = std::vector<unsigned char>(block_size + 4096);
  size_t offset = 0, available = 0;
  std::unique_ptr<XXH32_state_t, decltype(&XXH32_freeState)> hash{XXH32_createState(), XXH32_freeState};
  std::unique_ptr<ZSTD_DStream, decltype(&ZSTD_freeDStream)> stream{nullptr, ZSTD_freeDStream};
  ZSTD_inBuffer zin{nullptr, 0, 0};

  void file_read(void* data, size_t size) {
    // Old qs allowed short reads into uninitialized buffers. Require every byte.
    if(size > end - position) fail("Truncated legacy qs file");
    file.read(static_cast<char*>(data), static_cast<std::streamsize>(size));
    if(static_cast<size_t>(file.gcount()) != size) fail("Cannot read legacy qs file");
    position += size;
  }
  template<class T> T file_number() {
    T value{};
    file_read(&value, sizeof(value));
    return value;
  }
  void account() {
    offset = 0;
    decoded_bytes += available;
    if(has_hash && XXH32_update(hash.get(), decoded.data(), available) != XXH_OK)
      fail("Legacy qs checksum calculation failed");
  }
  bool fill() {
    Rcpp::checkUserInterrupt();
    available = 0;
    if(algorithm == 3) {
      ZSTD_outBuffer out{decoded.data(), decoded.size(), 0};
      while(out.pos == 0) {
        if(zin.pos == zin.size) {
          const size_t count = static_cast<size_t>(std::min<uint64_t>(compressed.size(), end - position));
          file_read(compressed.data(), count);
          zin = {compressed.data(), count, 0};
        }
        const size_t before = zin.pos;
        const size_t status = ZSTD_decompressStream(stream.get(), &out, &zin);
        if(ZSTD_isError(status)) fail("Damaged legacy qs zstd stream");
        // qs archive streams are flushed, not necessarily terminated frames.
        // EOF is valid only after the requested object has been completely read.
        if(out.pos == 0 && zin.pos == before) {
          if(position == end && zin.pos == zin.size) break;
          fail("Legacy qs decompression made no progress");
        }
      }
      available = out.pos;
    } else if(position < end) {
      if(algorithm == 4) {
        available = static_cast<size_t>(std::min<uint64_t>(decoded.size(), end - position));
        file_read(decoded.data(), available);
      } else {
        const uint32_t size = file_number<uint32_t>();
        if(size == 0 || size > compressed.size()) fail("Invalid legacy qs compressed block size");
        file_read(compressed.data(), size);
        if(algorithm == 0) {
          available = ZSTD_decompress(decoded.data(), decoded.size(), compressed.data(), size);
          if(ZSTD_isError(available)) fail("Damaged legacy qs zstd block");
        } else {
          const int result = LZ4_decompress_safe(reinterpret_cast<const char*>(compressed.data()),
              reinterpret_cast<char*>(decoded.data()), static_cast<int>(size), static_cast<int>(decoded.size()));
          if(result <= 0) fail("Damaged legacy qs lz4 block");
          available = static_cast<size_t>(result);
        }
        if(available == 0 || available > decoded.size()) fail("Invalid legacy qs decoded block size");
        ++blocks;
      }
    }
    account();
    return available != 0;
  }

public:
  unsigned shuffle = 0;
  explicit Input(const std::string& path) : file(std::filesystem::u8path(path), std::ios::binary) {
    if(!file) fail("Cannot open legacy qs file for reading");
    file.seekg(0, std::ios::end);
    const auto size = file.tellg();
    if(size < 0) fail("Cannot determine legacy qs file size");
    end = static_cast<uint64_t>(size);
    file.seekg(0);
    std::array<unsigned char, 4> header{};
    file_read(header.data(), header.size());
    if(header[0] != 0) {
      if(header != std::array<unsigned char, 4>{{0x0b, 0x0e, 0x0a, 0x0c}})
        fail("Legacy qs format not detected");
      file_read(header.data(), header.size()); // reserved bytes
      file_read(header.data(), header.size());
    }
    if(header[0] > 3) fail("Unsupported newer legacy qs format version");
    const uint16_t endian_test = 1;
    const unsigned endian = *reinterpret_cast<const unsigned char*>(&endian_test) == 1 ? 0 : 1;
    if(header[3] != endian) fail("Legacy qs byte order does not match this computer");
    algorithm = header[2] >> 4;
    if(algorithm > 4) fail("Unknown legacy qs compression algorithm");
    shuffle = header[2] & 15;
    has_hash = header[1] != 0;
    recorded_length = file_number<uint64_t>();
    if(!hash || XXH32_reset(hash.get(), 12345) != XXH_OK) fail("Cannot initialize legacy qs checksum");
    if(has_hash) {
      if(end - position < 4) fail("Missing legacy qs checksum");
      const uint64_t start = position;
      file.seekg(static_cast<std::streamoff>(end - 4));
      position = end - 4;
      recorded_hash = file_number<uint32_t>();
      end -= 4;
      file.seekg(static_cast<std::streamoff>(start));
      position = start;
    }
    if(algorithm == 3) {
      stream.reset(ZSTD_createDStream());
      if(!stream || ZSTD_isError(ZSTD_initDStream(stream.get()))) fail("Cannot initialize legacy qs decompressor");
    }
  }
  void read(void* target, size_t count) {
    auto* out = static_cast<unsigned char*>(target);
    while(count != 0) {
      if(offset == available && !fill()) fail("Truncated legacy qs object");
      const size_t step = std::min(count, available - offset);
      std::memcpy(out, decoded.data() + offset, step);
      offset += step;
      out += step;
      count -= step;
    }
  }
  template<class T> T number() {
    T value{};
    read(&value, sizeof(value));
    return value;
  }
  void numeric(void* target, size_t count, size_t width, bool shuffled) {
    if(!shuffled || count <= 4) { read(target, count); return; }
    // Preserve the original qs byte shuffle, including complex numbers (width 8).
    std::vector<unsigned char> bytes(count);
    read(bytes.data(), count);
    blosc_unshuffle(bytes.data(), static_cast<unsigned char*>(target), count, width);
  }
  void finish(bool strict) {
    auto issue = [strict](const char* message) {
      if(strict) fail(message);
      // A caller may turn warnings into errors; still close the input and free buffers.
      Rcpp::unwindProtect([&]() -> SEXP { Rf_warning("%s", message); return R_NilValue; });
    };
    bool trailing = offset != available;
    while(fill()) trailing = true;
    if(trailing) issue("Extra data after the legacy qs object");
    const uint64_t actual = algorithm < 3 ? blocks : decoded_bytes;
    if(recorded_length != 0 && recorded_length != actual)
      issue("Legacy qs recorded object length does not match the data");
    if(has_hash && recorded_hash != XXH32_digest(hash.get()))
      issue("Legacy qs checksum does not match; data may be corrupted");
  }
};

struct Header { SEXPTYPE type; uint64_t length; bool attributes = false; };

Header header(Input& input) {
  const unsigned tag = input.number<uint8_t>();
  const unsigned group = tag >> 5;
  if(group != 0) {
    static const SEXPTYPE types[] = {NILSXP, VECSXP, REALSXP, INTSXP, LGLSXP, STRSXP, NILSXP, NILSXP};
    if(group == 6) fail("Unsupported legacy qs object header");
    return {types[group], tag & 31U, group == 7};
  }
  if(tag == 0) return {NILSXP, 0};
  if(tag >= 1 && tag <= 20) {
    static const SEXPTYPE types[] = {VECSXP, REALSXP, INTSXP, LGLSXP, STRSXP};
    const unsigned width = (tag - 1) % 4;
    const uint64_t length = width == 0 ? input.number<uint8_t>() : width == 1 ? input.number<uint16_t>() :
        width == 2 ? input.number<uint32_t>() : input.number<uint64_t>();
    return {types[(tag - 1) / 4], length};
  }
  if(tag >= 21 && tag <= 24) {
    const uint64_t length = tag % 2 ? input.number<uint32_t>() : input.number<uint64_t>();
    return {static_cast<SEXPTYPE>(tag <= 22 ? CPLXSXP : RAWSXP), length};
  }
  if(tag == 30 || tag == 31)
    return {NILSXP, tag == 30 ? input.number<uint8_t>() : input.number<uint32_t>(), true};
  // General R serialization can contain functions/environments, even in attributes.
  // Do not execute unserialize or reconstruct unsupported internal objects.
  fail("Unsupported legacy qs object: only lists of matrices with ordinary data attributes are supported");
  return {NILSXP, 0};
}

SEXP string(Input& input) {
  const unsigned tag = input.number<uint8_t>();
  static const cetype_t encodings[] = {CE_NATIVE, CE_UTF8, CE_LATIN1, CE_BYTES};
  uint32_t length;
  if(tag & 32) length = tag & 31;
  else switch(tag & 31) {
    case 1: length = input.number<uint8_t>(); break;
    case 2: length = input.number<uint16_t>(); break;
    case 3: length = input.number<uint32_t>(); break;
    case 15: return NA_STRING;
    default: fail("Invalid legacy qs string header"); return R_NilValue;
  }
  if(length > INT_MAX) fail("Legacy qs string is too long");
  std::string bytes(length, '\0');
  input.read(bytes.data(), bytes.size());
  if(bytes.find('\0') != std::string::npos) fail("Embedded nul in legacy qs string");
  return Rcpp::unwindProtect([&]() -> SEXP {
    return Rf_mkCharLenCE(bytes.data(), static_cast<int>(length), encodings[tag >> 6]);
  });
}

SEXP object(Input& input, unsigned depth = 0) {
  if(depth > 128) fail("Legacy qs data attributes are nested too deeply");
  Header h = header(input);
  const uint64_t attributes = h.attributes ? h.length : 0;
  if(h.attributes) h = header(input);
  if(h.attributes) fail("Repeated legacy qs attribute header");
  if(depth == 0 && h.type != VECSXP) fail("Legacy qs input must be a list of matrices");
  if(h.length > static_cast<uint64_t>(R_XLEN_T_MAX) || h.length > std::numeric_limits<size_t>::max() / 16)
    fail("Legacy qs vector length is too large");
  if(h.type == NILSXP) {
    if(attributes) fail("Invalid attributes on legacy qs NULL");
    return R_NilValue;
  }
  // R allocation/attribute errors must unwind C++ buffers and the open input file.
  Rcpp::Shield<SEXP> out(Rcpp::unwindProtect([&]() -> SEXP {
    return Rf_allocVector(h.type, static_cast<R_xlen_t>(h.length));
  }));
  const size_t length = static_cast<size_t>(h.length);
  switch(h.type) {
    case VECSXP:
      for(size_t i = 0; i < length; ++i) {
        if(i % 4096 == 0) Rcpp::checkUserInterrupt();
        SET_VECTOR_ELT(out, i, object(input, depth + 1));
        if(depth == 0 && !Rf_isMatrix(VECTOR_ELT(out, i)))
          fail("Every element of a legacy qs list must be a matrix");
      }
      break;
    case STRSXP:
      for(size_t i = 0; i < length; ++i) {
        if(i % 4096 == 0) Rcpp::checkUserInterrupt();
        SET_STRING_ELT(out, i, string(input));
      }
      break;
    case REALSXP: input.numeric(REAL(out), length * 8, 8, input.shuffle & 4); break;
    case INTSXP: input.numeric(INTEGER(out), length * 4, 4, input.shuffle & 2); break;
    case LGLSXP: input.numeric(LOGICAL(out), length * 4, 4, input.shuffle & 1); break;
    case CPLXSXP: input.numeric(COMPLEX(out), length * 16, 8, input.shuffle & 8); break;
    case RAWSXP: input.read(RAW(out), length); break;
    default: fail("Unsupported legacy qs vector type");
  }
  for(uint64_t i = 0; i < attributes; ++i) {
    Rcpp::Shield<SEXP> name(string(input));
    if(name == NA_STRING || LENGTH(name) == 0) fail("Invalid legacy qs attribute name");
    Rcpp::Shield<SEXP> value(object(input, depth + 1));
    // SET_ATTRIB/SET_OBJECT were internal APIs. setAttrib also restores class flags.
    Rcpp::unwindProtect([&]() -> SEXP { return Rf_setAttrib(out, Rf_installChar(name), value); });
  }
  if(depth == 0 && Rf_isMatrix(out)) fail("Legacy qs input must be a list of matrices, not one matrix");
  return out;
}
} // namespace

// [[Rcpp::export(name = ".read_qs_matrices", rng = false)]]
SEXP read_qs_matrices(const std::string& path, bool strict) {
  Input input(path);
  Rcpp::Shield<SEXP> result(object(input));
  input.finish(strict);
  return result;
}
