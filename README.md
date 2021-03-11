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

## Deployment

TODO:

## How it works

### Client/Server communication

Client (browser) and Server(web server) are communicating using [WebSockets](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API).
When user initiates a procedure to process the input URLs, the following is happening:

![client-server-communication](./assets/client-server-communication.png)

### Date extraction

TODO:

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

## Contributors

- [Vitalii Elenhaupt](https://github.com/veelenga) - creator and maintainer
