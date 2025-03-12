# shared-sites
Shared code across keyman.com sites

## Distribution of asset files

1. Asset files should be stored in /assets (do not make changes to
   /_common/assets, as these files will be repopulated by build.sh)
2. Run build.sh after changing files under /_common or /assets, to rebuild
   .bootstrap-registry and repopulate /_common/assets
