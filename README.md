# HDE

HDE stands for **HTML Date Extractor**. A simple web app that can process HTTP URLs
in bulk and extract publication/modification dates from corresponding HTML pages.

## Usage & Development

``` sh
$ shards install
$ shards build --production
$ ./bin/hde
[development] Kemal is ready to lead at http://0.0.0.0:3000
```

Also note, that in order to be able to use a cache storage, a Redis must be available locally.
Otherwise, cache must be disabled:

``` sh
$ CACHE_DISABLED=1 ./bin/hde
```

For best performance, the app must be compiled with `--release` and `--Dpreview_mt` flags.

## Deployment

App is deployed to [Heroku](https://www.heroku.com/). The following steps can be performed to deploy it from scratch:

``` sh
$ heroku create hde-kagi --buildpack https://github.com/crystal-lang/heroku-buildpack-crystal.git
$ heroku git:remote -a hde-kagi
$ git push heroku master
```

Also note, that in order to be able to use a cache storage, a Redis resource must be added.
Otherwise, cache must be disabled:

``` sh
$ heroku config:set CACHE_DISABLED=1
```

## How it works

### Client/Server communication

Client (browser) and Server(web server) are communicating using [WebSockets](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API).
When user initiates a procedure to process the input URLs, the following is happening:

![client-server-communication](./assets/client-server-communication.png)

### Date extraction

Searching for a date in HTML is performed in the following steps:

1. Inspect the meta tags. Search is based on a whitelisted attributes which could indicate
the publication or modification date of the page.
2. Inspect the [JSON-LD](https://ru.wikipedia.org/wiki/JSON-LD) structure, which could contain
the publication or modification page of the page.
3. Inspect abbr tags. And try to find the most relevant date.
4. Inspect the time tags. And try to find the most relevant date.
5. Reduce HTML size and search for timestamps using regular expressions.
6. Reduce HTML size and search for the copyright year in meta or using regular expressions.

You can check the [specs](spec/html_date_spec.cr) for examples.

### Caching

Cache is used to avoid time-consuming steps for URL extraction.
When the URL is processed for the first time and the date is successfully extracted,
it is being cached in Redis using two keys (stored in transaction mode):

* `digest-${url}` - the base64digest representation of the content available by the URL
* `date-${url}` - the extracted date

When the same URL is processed for the second time, few operations are performed:

1. Lookup for a date in the cache using `date-${url}` key. Meaning if it is available, the URL was cached in the past.
2. `LastModifiedAt` response header is compared with the current date, meaning if the content was not modified, we can use the cached value.
3. Calculate the base64digest for the content and compare with a cached value available by `digest-${url}`.
Meaning if the values are equal, content was not changed and we can used the cached value.

If none of the above steps are true, the app starts extracting the date.

Cache can be disabled by using `CACHE_DISABLED=1` environment variable.

### Limitations and possible improvements

1. HTTP client can be improved. It follows the redirects with timeout and use cookies, however,
on some inputs it is constantly redirected. Maybe setting proper headers could help to emulated a browser better.

2. Client sends all available URLs in the textarea through the Web Socket in a single go.
This can be an issue on huge inputs. Splitting the input into chunks can help.

3. Taking a base64 digest from the hole HTML page is tricky.
The result will always be different if content on the page slightly changes on every request.
Preprocessing the HTML or extracting only relevant content from the HTML code and taking the
base64 from it (instead of a full HTML page) could improve the caching.

4. There is a number of extra steps which could be added to HTML Date extraction algorithm:

- parsing [Open Graph Protocol](https://ogp.me/) tags
- extract dates from URLs
- collecting all the dates on the page and determine the best one


## Contributors

- [Vitalii Elenhaupt](https://github.com/veelenga) - creator and maintainer
