commands used to generate file
docker run --name rocky-container rockylinux/rockylinux:8.5
docker export rocky-container | gzip > rocky-container.8.5.tar.gz

Based on information from
https://docs.rockylinux.org/guides/interoperability/import_rocky_to_wsl_howto/