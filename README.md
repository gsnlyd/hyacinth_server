# Hyacinth

Hyacinth is a collaborative data management and labeling tool for medical images.
The Hyacinth server provides a uniform and friendly interface for ingesting, transforming,
and labeling medical images in a collaborative environment.

<img width="1000" alt="Hyacinth Home Page Example" src="https://user-images.githubusercontent.com/48926197/205537542-d7ea3e16-c381-48b4-9f24-f09c8460cf04.png">


Here are some things you can do with Hyacinth:

* Manage large image datasets from a collaborative web app
* Create pipelines to transform data to different formats (e.g. convert DICOM images to Nifti volumes) via a friendly interface
* Create labeling jobs allowing multiple annotators to classify images based on provided criteria (pairwise comparison is also supported)

The Hyacinth web server can be run either on a local machine, or as a central
server for collaboration. Once the server is running, you can connect via any standard web
browser. Installation instructions can be found below.

## Installation

First, download a build of the Hyacinth server for your OS.

Builds are currently provided for the following operating systems:

* CentOS Stream 8

### Prerequisites

Hyacinth releases do not have any required dependencies, but there
are a couple of optional dependencies that are needed to use certain features.

If you want to use the built-in `slicer` driver, you will need a Python 3 installation.
If your OS does not come with Python 3 pre-installed, you can download an installer
from the [Python website](https://www.python.org/downloads/) or use your preferred package manager.

If you want to use the built-in `dicom_to_nifti` driver, you will need a dcm2niix installation.
See the [installation instructions](https://github.com/rordenlab/dcm2niix#install).

## Getting Started

The Hyacinth server is a packaged Elixir/Phoenix application, which can be started
via a script included with the release. However, before starting the server for the
first time, you need to create a database and add some data. The following steps will guide
you through this process.

1. Unzip your downloaded Hyacinth release and cd inside:

```console
$ unzip hyacinth.zip
$ cd hyacinth
```

2. Hyacinth is configured using environment variables. While not strictly necessary,
it is convenient to save these to a config file. An example config is
included below these steps - create a file named `prod.env` with the contents of this example.
Note that you must provide `SECRET_KEY_BASE` yourself for security. It must be set to an
80-character random alphanumeric string.

3. The Hyacinth server uses two directories to manage data. The `warehouse` directory is used to
store files, and the `transform` directory is used as temporary space when running pipelines.
These directories can be anywhere, but they must match your `prod.env` config file.
To create these directories (matching the example config file), run the following in your terminal:

```console
$ mkdir -p ~/hyacinth/warehouse
$ mkdir -p ~/hyacinth/transform
```

4. The Hyacinth server uses an SQLite database to store all application data. To create this database,
we need to run the `migrate` script. Run the following in your terminal:

```console
$ (source prod.env && ./bin/migrate)
```

5. (Optional) Now that our database is ready, we can add some data. For this, we will use the `new_dataset`
script. Hyacinth currently supports `dicom`, `nifti`, and `png` datasets. Assuming you have a dataset of
Nifti files stored under `/path/to/niftis`, the following command would create a `nifti` dataset
named `MyNiftiDataset`:

```console
$ source prod.env
$ ./bin/new_dataset MyNiftiDataset nifti /path/to/niftis
```

6. Now we can start our server using the `server` script. To start the server, run the command below and then point your
web browser to `localhost:4000` (the default host/port) to verify everything is working.

```console
$ (source .env && ./bin/server)
```

### Example Config

```bash
export DATABASE_PATH="~/hyacinth/hyacinth.db"
export WAREHOUSE_PATH="~/hyacinth/warehouse"
export TRANSFORM_PATH="~/hyacinth/transform"

export SECRET_KEY_BASE=[YOUR SECRET_KEY_BASE HERE: MUST BE AN 80-CHARACTER ALPHANUMERIC STRING]
```

## Developer Installation

**These instructions are for software developers who wish to modify Hyacinth's code. For user
installation instructions, see above.**

### Prerequisites

Hyacinth is an Elixir/Phoenix application, and an Elixir installation is required for compilation.
See the [Elixir installation instructions](https://elixir-lang.org/install.html).

## Compilation

1. Clone the `hyacinth_server` repository and `cd` inside.

2. (Optional) If this is your first time using Elixir, you will need to install Hex and Rebar
(package managers for the Elixir and Erlang ecosystems, respectively) to build Hyacinth. Both
can be installed via the `mix` build tool included with Elixir.

If you skip this step, you will be prompted to install both during step 3.

```console
$ mix local.hex
$ mix local.rebar
```

3. Install Hyacinth's dependencies from Hex (the Elixir package manager).

```console
$ mix deps.get
```

4. Run the Phoenix server in development mode. Once the server is running,
you can connect via your web browser.

```console
$ mix phx.server
```
