import json
import requests

# Your configuration here:
API_URL = "<YOUR_URL_HERE>/api/v2/saved-queries"
API_TOKEN = "Bearer <YOUR_BAERER_TOKEN_HERE>"

with open("customqueries.json", "r") as file:
    data = json.load(file)

queries = data.get("queries", [])

def send_query(name, query, description=""):
    headers = {
        "accept": "application/json",
        "Prefer": "0",
        "Content-Type": "application/json",
        "Authorization": API_TOKEN,
    }
    payload = {
        "name": name,
        "query": query,
        "description": description,
    }
    response = requests.post(API_URL, headers=headers, json=payload)
    return response.status_code, response.json()

for query_data in queries:
    name = query_data.get("name")
    category = query_data.get("category")
    for query_item in query_data.get("queryList", []):
        query = query_item.get("query")
        description = f"Category: {category}"
        status_code, response = send_query(name, query, description)
        print(f"Query '{name}' sent. Status: {status_code}, Response: {response}")

