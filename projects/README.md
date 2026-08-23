# Project Inventory

This inventory covers active project directories directly under `~/projects` as of 2026-08-23. It
excludes archived projects retained locally. It records machine and service dependencies, not every
transitive package dependency. Package manifests and each project's own README remain authoritative
for language-level dependencies.

| Project            | Purpose                                                              | GitHub status |
| ------------------ | -------------------------------------------------------------------- | ------------- |
| `agent-box-setup`  | Host and agent-VM setup instructions and shared agent configuration. | Public        |
| `ai`               | AI concepts, adoption, execution, and risk documentation.            | Public        |
| `clackworks`       | Product and workflow-automation specification.                       | Public        |
| `spcsim`           | Space-empire game design concept.                                    | Public        |
| `website`          | Current personal website and blog.                                   | Public        |
|                    |                                                                      |               |
| `dave-box-setup`   | Legacy machine-setup scripts and notes.                              | Private       |
| `dave-tax-advisor` | Tax-document filing and reconciliation helpers.                      | Private       |
| `infra`            | Public DNS, mail, hosting, and migration documentation.              | Private       |
| `macros`           | Personal nutrition and exercise tracking.                            | Private       |
| `nomap`            | Search and knowledge-management application.                         | Private       |
| `social-linkedin`  | LinkedIn recruiting-contact and message-management ideas.            | Private       |

## `agent-box-setup`

Machine configuration source for Ubuntu host and persistent agent VM. Depends on target-specific
host or VM setup, plus shared tools including Git, Node.js, Java, Python, Docker, coding-agent CLIs,
and browser automation. `user-home/` files must be symlinked into the user's home directory. The
project defines the shared dependencies used by active software projects; see `README.md` and
`verify-setup.sh` in its root.

## `ai`

Markdown knowledge base covering practical AI use, concepts, security, and agent-led engineering. No
runtime, service, or build dependency recorded. Needs Git and a Markdown editor; rendered links need
network access only when opened.

## `clackworks`

Product vision and specification repository for workflow automation. Current contents are Markdown
documentation, with no application runtime or external service configured. Needs Git and a Markdown
editor.

## `dave-box-setup`

Legacy predecessor of `agent-box-setup`, retained for its shell scripts and setup notes. Its update
and GitLab helpers require a POSIX shell, Git, `curl`, `jq`, and GitLab credentials when exporting
starred repositories. Treat machine instructions as historical until explicitly migrated into the
current setup repository.

## `dave-tax-advisor`

Tax-document filing workflow using PDF statement extraction and a Python matching helper. Requires
active local mount points under `mount/source` and `mount/template-readonly`; `scripts/mount-all.sh`
bind-mounts the configured Dropbox source and makes the example template read-only. Mounts need
administrator privileges and must be checked before file operations. Requires Python 3 and
`poppler-utils` for `pdftotext`; `python3-pypdf2` is an optional fallback. `paths.local` supplies
the source locations and is machine-local.

## `infra`

Documentation and planning for public-facing infrastructure. No local runtime is configured.
Operational work depends on access to registrar, DNS, mail, and hosting accounts; current plans use
Hetzner, Cloudflare, and Google Workspace. The intended website deployment depends on
`~/projects/website` and Cloudflare Workers.

## `macros`

Personal nutrition and exercise log. Markdown and YAML only: dependencies are a Markdown editor, the
local food database, and `profile.yaml`. Daily calculations are performed by an agent; no build,
runtime, or external service is configured.

## `nomap`

pnpm workspace containing Quarkus backend, React/TanStack frontend, and Playwright E2E harness.
Requires Node.js, pnpm, Java for Quarkus, Docker for local Elasticsearch and Quarkus Dev Services,
and Playwright browser binaries for browser tests. Local development starts Elasticsearch on port
9200, backend on 8080, and frontend on 3000. Production backend access additionally requires its
three `QUARKUS_ELASTICSEARCH_*` connection variables.

## `social-linkedin`

Early planning repository for consolidating email, recruiting messages, and LinkedIn contacts. It
currently contains only a TODO document; no runtime, service integration, or build dependency is
configured.

## `spcsim`

Design concept for a space-empire game. Current repository is Markdown-only, with no implemented
engine, runtime, assets, or external service dependency.

## `website`

Current personal website and blog built with Astro, Tailwind CSS, React islands, MDX, and sharp.
Requires Node.js LTS and pnpm; sharp performs native image optimization during builds. Local preview
uses the Astro dev server. Deployment requires either Cloudflare Workers credentials or Netlify;
`infra` documents the planned Cloudflare Workers deployment.
