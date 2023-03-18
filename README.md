A library for reading and writing text files or streams in any major Unicode format (UTF-8, UTF-16LE, UTF-16BE, UTF-32LE, UTF-32BE).

## Features

- Asynchronous extension methods to read from and write to UTF streams including as the whole buffer of text or as a list of lines.
- Similar asynchronous and synchronous methods to read from and write to UTF files as well as from _stdin_ and to _stdout_.
- Ability to specify a callback (closure) acting on every chunk of text or a line of text being read or written. This allows to avoid loading the whole content of a large file into memory before starting any processing. It also allows to avoid format conversions of large block of data after reading or before writing the result.

## Usage

See under the `Example` tab. All sample code files are under the sub-directory `example`.
