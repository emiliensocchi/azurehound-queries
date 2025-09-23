"""
    Uploads queries from 'customqueries.json' in bulk to BHCE, using the BHCE API.

"""
import json
import requests

# Your configuration here:
API_URL = "<YOUR_URL_HERE>/api/v2/saved-queries"
API_TOKEN = "Bearer <YOUR_BAERER_TOKEN_HERE>"

with open("customqueries.json", "r") as file:
    data = json.load(file)

queries = data.get("queries", [])

def send_query(name, query, description="", max_retries=5):
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

    for attempt in range(max_retries):
        try:
            response = requests.post(API_URL, headers=headers, json=payload, timeout=30)

            # Handle 429 specifically
            if response.status_code == 429:
                # Get retry delay from Retry-After header or use exponential backoff
                retry_after = response.headers.get('Retry-After')

                if retry_after:
                    # Server specified exact wait time
                    wait_time = int(retry_after)
                    print(f"Rate limited. Server requested {wait_time}s wait for query '{name}'")
                else:
                    # Use exponential backoff with jitter
                    wait_time = (2 ** attempt) + random.uniform(0, 1)
                    print(f"Rate limited. Waiting {wait_time:.1f}s before retry {attempt + 1}/{max_retries} for query '{name}'")

                if attempt < max_retries - 1:  # Don't wait on the last attempt
                    time.sleep(wait_time)
                    continue
                else:
                    print(f"Max retries exceeded for query '{name}' due to rate limiting")
                    return 429, {"error": "Rate limit exceeded after maximum retries"}

            # Try to parse JSON response
            try:
                json_response = response.json()
            except requests.exceptions.JSONDecodeError:
                json_response = {
                    "error": "Non-JSON response received",
                    "content": response.text[:500],
                    "content_type": response.headers.get('content-type', 'unknown')
                }

            return response.status_code, json_response

        except requests.exceptions.Timeout:
            print(f"Timeout on attempt {attempt + 1} for query '{name}'")
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)
                continue
            return None, {"error": "Request timeout after retries"}

        except requests.exceptions.ConnectionError:
            print(f"Connection error on attempt {attempt + 1} for query '{name}'")
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)
                continue
            return None, {"error": "Connection error after retries"}

        except Exception as e:
            return None, {"error": f"Unexpected error: {str(e)}"}

    return None, {"error": "Max retries exceeded"}

for query_data in queries:
    name = query_data.get("name")
    category = query_data.get("category")
    for query_item in query_data.get("queryList", []):
        query = query_item.get("query")
        description = f"Category: {category}"
        status_code, response = send_query(name, query, description)
        print(f"Query '{name}' sent. Status: {status_code}, Response: {response}")
