#!/bin/sh


# === activeadmin-mongoid-blog ===
# https://github.com/alexkravets/activeadmin-mongoid-blog
#
# Description:
#   Blog app on the top of activeadmin and mongoid, using redactor and
#   select2 plugins. Could be useful for almost every activeadmin based project.
# 
# Installation:
#   export project_name=new_blog ; curl https://raw.github.com/alexkravets/activeadmin-mongoid-blog/master/install.sh | sh


set -e

rails new $project_name -T -O
cd $project_name


# Gems
echo '
gem "bson_ext"
gem "mongoid"
gem "devise"
gem "activeadmin-mongoid"
gem "redactor-rails", :git => "git://github.com/alexkravets/redactor-rails.git"
gem "activeadmin-mongoid-blog"
gem "therubyracer"
gem "twitter-bootstrap-rails"' >> Gemfile


bundle


rails g mongoid:config
rails g devise:install
rails g active_admin:install
rails g redactor:install
rails g active_admin:blog:install blog
rails g bootstrap:install


# Tweak active_admin.js
echo '//= require activeadmin_mongoid_blog' >> app/assets/javascripts/active_admin.js


# Tweak active_admin.css.scss
cat app/assets/stylesheets/active_admin.css.scss > temp_file.tmp
echo '//= require activeadmin_mongoid_blog' > app/assets/stylesheets/active_admin.css.scss
cat temp_file.tmp >> app/assets/stylesheets/active_admin.css.scss
rm temp_file.tmp


# Tweak application.css.scss
echo '/*
 *= require bootstrap_and_overrides
 *= require_self
 */

.pagination .page.current {
  float:left;
  padding:0 14px;
  line-height:34px;
  text-decoration:none;
  border:1px solid #DDD;
  border-left-width:0;
  color:#999;
  cursor:default;
  background-color:whiteSmoke;
}
.pagination span:first-child, .pagination .first a { border-left-width:1px; }' > app/assets/stylesheets/application.css


# Tweak application.js
echo '//= require jquery
//= require jquery_ujs
//= require twitter/bootstrap
//= require bootstrap
'  > app/assets/javascripts/application.js


# Fix default mongoid.yml
echo 'development:
  host: localhost
  database: '$project_name'

test:
  host: localhost
  database: '$project_name'_test

production:
  uri: <%= ENV["MONGO_URL"] %>' > config/mongoid.yml


# Remove migrations, we don't need them with mongoid
rm -Rfd db/migrate


# Fix seed.rb file to generate first admin user
echo 'puts "EMPTY THE MONGODB DATABASE"
Mongoid.master.collections.reject { |c| c.name =~ /^system/}.each(&:drop)

puts "SETTING UP DEFAULT ADMIN USER"
AdminUser.create!(:email => "admin@example.com", :password => "password", :password_confirmation => "password")
' > db/seed.rb


# Create default admin user
rake db:seed

