#!/usr/bin/env bash
set -e
set -o pipefail

chown -R deploy:deploy /home/deploy/epetitions/releases/<%= release %>

su - deploy <<'EOF'
ln -nfs /home/deploy/epetitions/shared/tmp /home/deploy/epetitions/releases/<%= release %>/tmp
ln -nfs /home/deploy/epetitions/shared/log /home/deploy/epetitions/releases/<%= release %>/log
ln -nfs /home/deploy/epetitions/shared/bundle /home/deploy/epetitions/releases/<%= release %>/vendor/bundle
ln -nfs /home/deploy/epetitions/shared/assets /home/deploy/epetitions/releases/<%= release %>/public/assets
ln -s /home/deploy/epetitions/releases/<%= release %> /home/deploy/epetitions/current_<%= release %>
mv -Tf /home/deploy/epetitions/current_<%= release %> /home/deploy/epetitions/current
cd /home/deploy/epetitions/current && bundle install --without development test --deployment --quiet
cd /home/deploy/epetitions/current && bundle exec rake db:migrate
cd /home/deploy/epetitions/current && bundle exec rake assets:precompile
if [ ${SERVER_TYPE} = "worker" ] ; then cd /home/deploy/epetitions/current && bundle exec whenever -w ; else echo not running whenever ; fi
EOF
