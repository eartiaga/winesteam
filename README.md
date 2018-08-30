Sid-based Steam Docker
======================

This is a steam launcher based on Debian Sid (a.k.a. Unstable) and wine (https://www.winehq.org),
ready to run in a Docker container.

It expects relatively new NVidia graphic cards (i.e. those supported by
non-legacy NVidia drivers).


Acknowledgments
---------------

This is heavily inspired in other steam-in-a-docker containers, especially:
- https://hub.docker.com/r/andrey01/steam/
- https://hub.docker.com/r/tianon/steam/

Of course, thanks to the Wine team also :-)
- https://www.winehq.org

For the impatient
-----------------

1. Clone this repository
    `git clone https://github.com/eartiaga/winesteam`

2. Go into the repository's root directory
    `cd winesteam`

3. Build the image
    `docker-compose build`

4. Launch the container
    `STEAM_USER=$(id -ru) docker-compose up`

   or alternatively:
    `./winedock.sh ./data`

Configuration
-------------

The container is affected by some environment variables, with default values
defined in the `.env` file in the repository root directory. Environment
variables take precedence over the file. The relevant variables are:

* WINE_DATADIR: The directory that the Steam launcher will use to store
  persistent local data. It defaults to a directory named `data` in the repository's
  root.

* WINE_BITS: Expected values are 64 or 32, indicating if a 64 or 32 bit environment
  should be used.

* STEAM_UID: This should be the uid of a user with write permissions on the
  `STEAM_DATADIR` directory. It defaults to `1001` (a convenient value for
  my own setup ;-) (Please, be sensible and avoid the root user and 0777
  permissions...)

* STEAM_USER: The name of the non-root user inside the container. It defaults
  to `steam`, but it can be changed according to taste.

* STEAM_SKIP: Instead of starting steam, perform an alternative action:
** yes: leave the container on stand-by
** shell: start an interactive shell
** cfg: run winecfg
** yes: execute the contents of $WINE_DATADIR/launch.rc, instead of steam
** no: perform the default action (i.e. start steam)

Troubleshooting
---------------

* In case you have trouble resolving dns names when building the docker, make sure
  you have set the dns servers in the /etc/docker/daemon.json file. It should contain
  something like:

  ```
  {
    ...
    "dns": [ "<your_dns_server_ip>" ]
  }
  ```
  (create the file if it does not exist; and you may use google's dns server 8.8.8.8 in case of
  need)

Disclaimer
----------

There might be bugs. Use at your own risk.

