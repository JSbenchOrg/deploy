### Setup

* Copy `.env.dist` to `.env` and replace with real credentials.
* Install `ncftp` (`ncftpput`)

----


### Update

Run `./run.sh` to fetch the latest versions and deploy to stage. Each repo will have its own MAJOR.MINOR version as a destination folder.

> @todo - the client is pushed to the root https://stage.jsbench.org, without the versioned folder because of multiple issues with paths.

----


### Known issues

- [x] migrations and seeds - by calling curl on migrate.php. Run ./run.sh
- [x] report is being displayed / pushed to announce a successful push
- [ ] @todo each db table should have a prefix for the version (if more versions are to be staged and to avoid db conflicts)
- [ ] it doesn't check for the existing folder on stage, will just upload / append to it
