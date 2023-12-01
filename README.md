# GNU Make files for EKG engineers

DRAFT

This repo contains one `.mk` file per topic to be included
by other `.mk` files or by top level `Makefile` files (such as [/Makefile](../Makefile))
in your own repo.

These so-called "make files" are used by the infamous 
[GNU Make utility](https://www.gnu.org/software/make/manual/html_node/index.html)
which is an ancient but still very useful tool to get tasks executed in the
right order.

## Supported tools

- [AWS CLI](./aws-cli.mk)
- [AWS Cloudfront](./aws-cloudfront.mk)
- [AWS Cloudwatch](./aws-cloudwatch.mk)
- [AWS IAM](./aws-iam.mk)
- [AWS Sagemaker](./aws-sagemaker.mk)
- [Azure](./azure.mk)
- [Azure CLI](./azure-cli.mk)
- [HomeBrew](./brew.mk)
- [Cargo](./cargo.mk)
- [CLang](./clang.mk)
- [Cocogitto](./cog.mk)
- [Curl](./curl.mk)
- [Docker](./docker.mk)
- [Git](./git.mk)
- [JQ](./jq.mk)
- [GNU Make](./make.mk)
- [Next.js](./nextjs.mk)
- [Node.js](./nodejs.mk)
- [OpenNext](./open-next.mk)
- [OxiGraph](./oxigraph.mk)
- [pip](./pip.mk)
- [pipx](./pipx.mk)
- [pnpm](./pnpm.mk)
- [Poetry](./poetry.mk)
- [Rust](./rust-target.mk)
- [Rustup](./rustup.mk)
- [Sops](./sops.mk)
- [Terraform](./terraform.mk)
- [Terragrunt](./terragrunt.mk)
- [TFlint](./tflint.mk)
- [EKGF Use Case](./use-case.mk)
- [zip](./zip.mk)

## How to use it

On Mac OS, use `gmake` instead of `make`:

```shell
gmake <some target>
```

or, on Windows or Linux:

```shell
make <some target>
```

Where `<some target>` can be something like:

- `help`
- `all`
- `deploy`
- `build`
- `test`

## How to install it

### On Mac OS:

First make sure that you have `brew` (or "HomeBrew") installed (test this by
executing `brew` on the command line).

Then use `brew install make` to install GNU Make.

### On Windows:

If you have ["Chocolatey"](https://chocolatey.org/install) installed 
you can simply use:

```
choco upgrade chocolatey
choco install make
```

Articles:

- https://leangaurav.medium.com/how-to-setup-install-gnu-make-on-windows-324480f1da69

## Rationale

Why use ancient technology like GNU Make? Rather than using something more modern like Chef, Puppet, or Ansible?

- Even though GNU Make is ancient, it is still very useful and widely used, especially in the C,C++ and Linux world.
- GNU Make is relative simple and easy to use and very fast.
- GNU Make is available on all platforms, including Windows, Linux and Mac OS.
- We have experience doing the same with other technologies such as Chef or giant Bash scripts, 
  but that turned out to be more complex and less maintainable than using GNU Make. 
  And requires more specific knowledge in the team, we want every developer to be able to use and improve this,
  not just your local Chef expert.

## Principles

- Reuse existing package managers as much as possible such as HomeBrew, Chocolatey, apt-get, yum, etc.

