Icinga dashboard for Dashing
============================

This is a example dashboard for Icinga based on the Dashing framework.

![screenshot](screenshot.png =200px)

References
----------

Dashing Dashboard Software: http://shopify.github.io

Dashing on GitHub: https://github.com/shopify/dashing

Files to check
--------------

To understand how this dashboard works have a look at the following files:

* config.ru
* dashboards/icinga.erb
* jobs/icinga.rb
* widget/simplemon/\*
* widget/table/\*
* assets/stylesheets/icinga.scss

Quick Start for this Dashboard
------------------------------

Make sure you have Ruby and the Tool "gem" installed on your system.

```
apt-get install ruby rubygems bundler
# on newer Debian or Ubuntu systems
# rubygems has been moved into the ruby package
```

The next command will use the ruby bundler to install all gem dependencies.

```
bundle
```

Tip: to install dashing in your user context use:

```
bundle install --path ~/.gem

# but you need to add the bin dir to your path
for bin in `echo .gem/ruby/*/bin`; do
  PATH="$HOME/$bin:$PATH"
done
```

```
dashing start
```

Now go to http://localhost:3030/

License
-------

- (c) 2014 NETWAYS GmbH <info@netways.de>
- (c) 2014 Markus Frosch <markus@lazyfrosch.de>

Other resources and basic templates:

- Copyright (c) 2014 Shopify and contributors

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

