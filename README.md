Jbot
====

An IRC Logger that uses redis to expose logs to the web. 

How to Install
----------

Ensure you have Ruby, Rubygems and Bundler installed then:

```
#Clone Repo:
git clone git@github.com:BukhariH/jBot.git
#cd into the directory
#Run:
bundle install
compass compile
#Set ENV variable for website
#On windows:
set LOGURL=Your-IP-or-Domain
#On Mac or Unix
export LOGURL=Your-IP-or-Domain
#Start the logger, redis and the Web View:
foreman start
    
```

How to use
----------

Pretty simple:

```
    $date - Gives you the date in GMT
    $news - Top three BBC Headlines
    $rand - 50/50 Game! 50% of the time r/aww and the other 50% r/wtf
    $xkcd - latest xkcd comic
    Jbot: - Prefix a sentence with this command to chat with Jbot
    $rwhois - followed by a reddit username gives information about that user
    $log - Tells you where you can find the weblogs for the current channel
```

 License
-------

MIT

Authors
-------

Made by __Hasnain Bukhari__ based on __Shao-Chung Chen__'s LogBot