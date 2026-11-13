# iiq-build-setup

A GitHub Action that prepares a runner to build SailPoint IdentityIQ (IIQ) code.

IIQ builds compile against proprietary JARs such as `identityiq.jar`, which can't be committed to a public repository. This action fetches them at build time from a private repository you control, stages them under the names your build expects, and sets up Java, Gradle and, if you ask for it, Node.js.

No SailPoint binaries are included in this repository.

## Usage

Run it after checking out your own repository. A later `actions/checkout` of the workspace would delete the staged JARs.

```yaml
steps:
  - uses: actions/checkout@v4

  - id: iiq
    uses: instrumental-id/iiq-build-setup@v1
    with:
      versions: "8.4:lib/sailpoint 9.0:lib-9.0/sailpoint"
      app-id: ${{ vars.IIQ_BUILD_APP_ID }}
      app-private-key: ${{ secrets.IIQ_BUILD_APP_PRIVATE_KEY }}

  - if: steps.iiq.outputs.available == 'true'
    run: ./gradlew build
```

For a plugin with a Node-built UI, add Node:

```yaml
  - id: iiq
    uses: instrumental-id/iiq-build-setup@v1
    with:
      versions: "8.4:lib/sailpoint"
      node-version-file: ui/.nvmrc
      node-cache: npm
      node-cache-dependency-path: ui/package-lock.json
      app-id: ${{ vars.IIQ_BUILD_APP_ID }}
      app-private-key: ${{ secrets.IIQ_BUILD_APP_PRIVATE_KEY }}
```

If your Gradle build uses a plugin that downloads its own Node (such as `com.github.node-gradle.node` with `download = true`), you don't need these inputs.

With the default settings, the first example stages:

| Source (in the private repo)                        | Destination                              |
|-----------------------------------------------------|------------------------------------------|
| `lib/iiq-versions/identityiq-8.4.jar`               | `lib/sailpoint/identityiq.jar`           |
| `lib/iiq-versions/connector-bundle-identityiq-8.4.jar` | `lib/sailpoint/connector-bundle-identityiq.jar` |
| `lib/iiq-versions/pam-credential-8.4.jar` (if present) | `lib/sailpoint/pam-credential.jar`    |
| ...and the same for 9.0 into `lib-9.0/sailpoint/`   |                                          |

## Inputs

| Input | Default | Description |
|---|---|---|
| `versions` | *(required)* | Whitespace-separated `VERSION:DEST_DIR` pairs. |
| `jars` | `identityiq connector-bundle-identityiq` | JARs that must exist for every version. |
| `optional-jars` | `pam-credential` | JARs staged only when present. |
| `app-id` / `app-private-key` | | GitHub App credentials. Preferred. |
| `token` | | A token with read access to the source repo. |
| `ssh-key` | | A read-only deploy key for the source repo. |
| `source-repository` | `instrumental-id/iiq-common-library` | Private repo holding the JARs. |
| `source-ref` | default branch | Branch, tag or SHA to read from. |
| `source-path` | `lib/iiq-versions` | Directory of `NAME-VERSION.jar` files. |
| `fail-if-unavailable` | `false` | Fail instead of skipping when no credentials are supplied. |
| `java-version` | `21` | Java to install; empty to skip. |
| `java-distribution` | `temurin` | Distribution for `actions/setup-java`. |
| `setup-gradle` | `true` | Whether to run `gradle/actions/setup-gradle`. |
| `node-version` | | Node.js to install, e.g. `20` or `lts/*`. Node is skipped unless this or `node-version-file` is set. |
| `node-version-file` | | Read the Node.js version from a file, e.g. `.nvmrc` or `ui/package.json`. |
| `node-cache` | | Package manager cache to restore: `npm`, `yarn` or `pnpm`. |
| `node-cache-dependency-path` | | Lock file(s) for the cache key when not at the repo root, e.g. `ui/package-lock.json`. |

## Outputs

| Output | Description |
|---|---|
| `available` | `true` when the JARs were staged, `false` when no credentials were supplied. |

## Credentials

Supply one of these. If more than one is given, the first in this list wins.

1. **GitHub App (recommended for an organization).** Create an app owned by the organization with **Repository permissions → Contents: Read-only**, install it on the source repository only, and store its ID as a variable and its private key as a secret. Each run gets a short-lived token scoped to that one repository, and nothing is tied to a person.
2. **Token.** A fine-grained personal access token with Contents read access to the source repository.
3. **Deploy key.** A read-only SSH deploy key added to the source repository.

Organization-level secrets let you set the credentials once. On GitHub Free, organization secrets are only available to public repositories.

## Fork pull requests

GitHub does not pass secrets to workflows triggered by pull requests from forks. In that case this action skips the fetch, emits a notice and sets `available` to `false`, so you can skip the build steps instead of failing. Set `fail-if-unavailable: true` on jobs that must always build, such as publishing from `main`.

Don't work around this with `pull_request_target`. Running untrusted PR code with secrets available is the most common way secrets leak from public repositories.

## Keeping the JARs private

- Don't cache the staged directories with `actions/cache`. On a public repository, fork PRs can restore caches created on the default branch.
- Don't upload the staged directories with `actions/upload-artifact`. Artifacts on a public repository can be downloaded by anyone.
- Keep the IIQ JARs as `compileOnly` dependencies so they aren't bundled into what you publish.

## License

Apache 2.0. See [LICENSE](LICENSE).
