# Hyacinth

Hyacinth is a collaborative data management and labeling tool for medical images.


## Installation

First, download a build of the Hyacinth server for your OS.

Builds are currently provided for the following operating systems:

* CentOS Stream 8


### Prerequisites

Hyacinth server releases do not have any hard dependencies, however there
are a couple of optional dependencies to use certain features.

If you want to use the built-in `slicer` driver, you will need a Python 3 installation.
If your OS does not come with Python 3 pre-installed, you can download an installer
from the [Python website](https://www.python.org/downloads/) or use your preferred package manager.

If you want to use the built-in `dicom_to_nifti` driver, you will need a dcm2niix installation.
See [installation instructions](https://github.com/rordenlab/dcm2niix#install).


### Getting Started

The Hyacinth server is a packaged Elixir/Phoenix application, which can be started
via a script included with the release. However, before starting for the first time,
you need to create a database and add some data. The following steps will guide
you through this process.

1. Unzip your downloaded Hyacinth release and cd inside:

```
$ unzip hyacinth.zip
$ cd hyacinth
```

2. Hyacinth is configured using environment variables. While not strictly necessary,
it is convenient to save these to a config file for convenience. An example config is
included below these steps - create a file named `prod.env` with the contents of this example.
Note that you must provide `SECRET_KEY_BASE` yourself for security. It must be set to an
80-character random alphanumeric string.

3. The Hyacinth server uses two directories to store your datasets and generate new datasets.
The `warehouse` directory is used to store files, and the `transform` directory is
used as temporary space when running pipelines. These directories can be anywhere, but they must
match your `prod.env` config file. To create these directories (matching the example config file),
run the following in your terminal:

```
mkdir -p ~/hyacinth/warehouse
mkdir -p ~/hyacinth/transform
```

4. The Hyacinth server uses an SQLite database to store all application data. To create this database,
we need to run the migration script. Run the following in your terminal:

```
$ (source prod.env && ./bin/migrate)
```

5. (Optional) Now that our database is ready, we can add some data. For this, we will use the `new_dataset`
script. Hyacinth currently supports `dicom`, `nifti`, and `png` datasets. To use the script, see the following
example:

```
$ source prod.env
$ ./bin/new_dataset MyNiftiDataset nifti /path/to/niftis
```

6. Now we can start our server. To start the server, run the command below and then point your
web browser to `localhost:4000` (the default host/port) to verify everything is working.

```
$ (source .env && ./bin/server)
```
