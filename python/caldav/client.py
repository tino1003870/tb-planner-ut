#!/usr/bin/env python3

import base64
import urllib.request
import urllib.error


class CalDAVClient:
    """
    Minimaler CalDAV-Client für den TB-Planner.

    Unterstützt zunächst:
      - PROPFIND
      - GET
      - PUT
      - DELETE

    Authentifizierung:
      HTTP Basic Authentication
    """

    def __init__(self, base_url, username, password):
        self.base_url = base_url.rstrip("/") + "/"

        token = base64.b64encode(
            f"{username}:{password}".encode("utf-8")
        ).decode("ascii")

        self.auth_header = "Basic " + token

    def _request(self, url, method="GET", data=None, headers=None):
        request_headers = {
            "Authorization": self.auth_header,
        }

        if headers:
            request_headers.update(headers)

        request = urllib.request.Request(
            url,
            data=data,
            method=method,
            headers=request_headers,
        )

        return urllib.request.urlopen(request, timeout=30)

    def get(self, url):
        with self._request(url, "GET") as response:
            return response.status, response.headers, response.read()

    def put(self, url, data):
        if isinstance(data, str):
            data = data.encode("utf-8")

        with self._request(
            url,
            "PUT",
            data=data,
            headers={
                "Content-Type": "text/calendar; charset=utf-8",
            },
        ) as response:
            return response.status, response.headers, response.read()

    def delete(self, url):
        with self._request(url, "DELETE") as response:
            return response.status, response.headers, response.read()

    def propfind(self, url, body):
        if isinstance(body, str):
            body = body.encode("utf-8")

        with self._request(
            url,
            "PROPFIND",
            data=body,
            headers={
                "Content-Type": "application/xml; charset=utf-8",
                "Depth": "1",
            },
        ) as response:
            return response.status, response.headers, response.read()

