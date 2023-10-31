import json
import os
import openai
openai.api_key = os.getenv("OPENAI_API_KEY")


def reset_gps_location():
    """Set the current gps location"""
    print(f"reset gps location")
    return "gps location is reset"


def visit_locations(locations):
    print(f"Visited {locations}")
    return f"{len(locations)} locations are visited."


def run_conversation():
    # Step 1: send the conversation and available functions to GPT
    messages = [
        {"role": "system",
         "content": "I am an expert in palm oil trees."
        },
        {"role": "user",
                 "content": """I have trees with gps locations as follow:
                 
                  location 1: latitude 1.0 and longitude 1.0 with 78 trees lack of nitrogen and 10 trees healthy,
                  location 2: latitude 2.0 and longitude 2.0 with 18 trees lack of nitrogen and 20 trees healthy,
                  location 3: latitude 3.0 and longitude 3.0 with 98 trees lack of nitrogen and 20 trees healthy
                 
                  Write 3 days plan to treat the tree and include the gps 
                  location. Make sure the location with the most trees 
                  that is lack of nitrogen are treated first. 
                  Visit maximum of one gps location per day, and not more than 1 location. Maximize travel time.
                  """}]
    '''
    {
        "name": "reset_gps_location",
        "description": "Reset all gps location",
        "parameters": {
            "type": "object",
            "properties": {

            },
            "required": [],
        },
    },
    '''
    functions = [
        {
            "name": "visit_locations",
            "description": "Visit a location",
            "parameters": {
                "type": "object",
                "properties": {
                    "locations": {
                        "type": "array",
                        "description": "the gps locations",
                        "items": {
                            "type": "object",
                            "properties": {
                                "id": {"type": "number", "description": "id"},
                                "longitude": {"type": "number", "description": "longitude"},
                                "latitude": {"type": "number", "description": "latitude"},
                            }
                        }
                    }
                },
                "required": ["locations"]
            },
        }
    ]
    response = openai.ChatCompletion.create(
        model="gpt-3.5-turbo-0613",
        messages=messages,
        functions=functions,
        function_call="auto",  # auto is default, but we'll be explicit
    )
    response_message = response["choices"][0]["message"]

    # Step 2: check if GPT wanted to call a function
    if response_message.get("function_call"):
        # Step 3: call the function
        # Note: the JSON response may not always be valid; be sure to handle errors
        available_functions = {
            "visit_locations": visit_locations,
            "reset_gps_location": reset_gps_location,
        }  # only one function in this example, but you can have multiple
        function_name = response_message["function_call"]["name"]
        if function_name == "python":
            print(response_message["function_call"]["arguments"])
        elif function_name in available_functions:
            function_to_call = available_functions[function_name]
            function_args = json.loads(response_message["function_call"]["arguments"])
            function_response = function_to_call(**function_args)
        else:
            print(f"missing {function_name}")

        # Step 4: send the info on the function call and function response to GPT
        messages.append(response_message)  # extend conversation with
        # assistant's reply
        messages.append(
            {
                "role": "function",
                "name": function_name,
                "content": function_response
            }
        )  # extend conversation with function response
        second_response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo-0613",
            messages=messages,
            functions=functions
        )  # get a A
        assistant_message = second_response["choices"][0]["message"]
        messages.append(assistant_message)
        return messages


print(run_conversation())
