import sys
import os
import json

from pathlib import Path
from typing import Any
from urllib.parse import quote_plus as urlencode

import requests


DIGIKEY_AUTH_URL_V4 = "https://api.digikey.com/v1/oauth2/authorize"
DIGIKEY_TOKEN_URL_V4 = "https://api.digikey.com/v1/oauth2/token"
DIGIKEY_PRODUCT_SEARCH_URL_V4 = "https://api.digikey.com/products/v4/search/keyword"


class DigiKey:
    client_id: str
    client_secret: str
    access_token: str | None = None

    def __init__(self, client_id: str | None = None, client_secret: str | None = None):
        self.client_id = client_id or os.environ["DIGIKEY_CLIENT_ID"]
        self.client_secret = client_secret or os.environ["DIGIKEY_CLIENT_SECRET"]

        # Sanity Check That Authorisation Details Was Provided
        if not self.client_id or not self.client_secret:
            raise ValueError("Missing client_id or client_secret")

    def product_details(self, product_id: str) -> dict[str, Any]:
        self.authenticate()
        assert self.access_token is not None

        return self.oauthv2_productdetails(
            self.client_id, self.access_token, product_id
        )

    def authenticate(self) -> None:
        if self.access_token is not None:
            return
        oauth_token = self.oauthV2_get_simple_access_token(
            DIGIKEY_TOKEN_URL_V4, self.client_id, self.client_secret
        )
        access_token = oauth_token["access_token"]
        assert access_token is not None
        self.access_token = access_token

    def oauthV2_get_simple_access_token(self, url, client_id, client_secret):
        # Get the simple access token required for 2 Legged Authorization OAutV2.0 flow
        # This is typically used for basic search and retreival of publically avaliable information
        response = requests.post(
            url,
            data={
                "client_id": client_id,
                "client_secret": client_secret,
                "grant_type": "client_credentials",
            },
        )
        return response.json()

    def oauthv2_productdetails(
        self, client_id: str, access_token: str, product_id: str
    ):
        url = f"https://api.digikey.com/products/v4/search/{urlencode(product_id)}/productdetails"
        response = requests.get(
            url,
            headers={
                "X-DIGIKEY-Locale-Site": "DE",
                "X-DIGIKEY-Locale-Language": "EN",
                "X-DIGIKEY-Locale-Currency": "EUR",
                "X-DIGIKEY-Client-Id": client_id,
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
        )
        return response.json()
