# CPEE-LLM

This gem realizes the 3 CPEE Conversational Agents

* CM-A for creating models
* EP-A for selecting endpoints
* DF-A for creating and validating dataflow

# Installation

```bash
gem install --user cpee-llm
mkdir ~/run
cd ~/run
cpee-llm new cllm # scaffold; you maybe need to add installed bins to PATH
cd cllm
vim cpee-llm.conf # only add the connect adapters you need
vim connect_gemini # add your key
vim connect_gpt # add your key
vim connect_morpheus # add your key, and change url of you morpheus hosting
# connect adapter can be added or deleted as you wish, see rubyllm config for
# possible config options. The myllm variable always contains the requested
# model.
./cpee-llm start
```

These commands install and scaffold a sample server. In the same directory you
see a set of sample connectors.

# Supported LLMs

We support all LLMs that https://rubyllm.org supports. Check it out.


---

# 1. Text → Process Model

```http
POST https://cpee.org/llm/
```

Converts a textual process description into a process model or adapts an existing model.

## Parameters

| Parameter | Type | Description |
|------------|------|-------------|
| rpst_xml | text/xml | Existing CPEE XML model |
| user_input | text/plain | Natural language process description |
| llm | text/plain | LLM identifier |
| prompt_type | text/plain | `generate_noendpoints` or `adapt_noendpoints` |
| temperature | text/plain (optional) | Defaults to 0 |

**Important:** Parameter order matters.

rpst\_ xml contains the content of the  `<description>` tag from the CPEE testset

### Empty RPST Example

```xml
<description xmlns="http://cpee.org/ns/description/1.0"/>
```

## Response

```json
{
  "user_input": "...",
  "used_llm": "...",
  "input_cpee": "...",
  "input_intermediate": "...",
  "output_intermediate": "...",
  "output_cpee": "...",
  "status": "..."
}
```

### Key Outputs

- `output_intermediate` → generated process model in Mermaid .js format
- `output_cpee` →  CPEE XML process model

## cURL Example

```bash
curl -X POST https://cpee.org/llm/ \
  -H 'Content-Type:multipart/form-data' \
  -F "rpst_xml=@cpee_empty_example;type=text/xml" \
  -F "user_input=Create task A after dismissal review.;type=text/plain" \
  -F "llm=gemini-2.5-flash-lite;type=text/plain" \
  -F "prompt_type=generate_noendpoints;type=text/plain"
```

---

# 2. Process Model → Text


```http
POST https://cpee.org/llm/text/llm/
```

Generates a textual process description from a process model.

## Parameters

| Parameter | Type |
|-----------|------|
| rpst_xml | text/xml |
| llm | string |

## Response

```json
{
  "input_cpee": "...",
  "input_intermediate": "...",
  "output_text": "...",
  "status": "..."
}
```

### Key Output

- `output_text` → Generated process description

## cURL Example

```bash
curl -X POST https://cpee.org/llm/text/llm/ \
  -H 'Content-Type:multipart/form-data' \
  -F "rpst_xml=@cpee_example;type=text/xml" \
  -F "llm=gemini-2.5-flash-lite"
```

---

# 3. Generic Functionality

```http
POST https://cpee.org/llm/generic/
```

Performs arbitrary LLM tasks using a system prompt and user input.

## Parameters

| Parameter | Type |
|-----------|------|
| llm | text/plain |
| user_input | text/plain |
| system_prompt | text/plain |
| format | text/plain (`true`/`false`) |
| temperature | text/plain (optional) |

## Response

```json
{
  "user_input": "...",
  "used_llm": "...",
  "system_prompt": "...",
  "llm_response": "...",
  "status": "..."
}
```

### Notes

- `format=true` requests JSON output (guarantees valid JSON but not any specific structure).

List of supporteb providers: https://rubyllm.com/chat/#getting-structured-output

## cURL Example

```bash
curl -X POST https://cpee.org/llm/generic/ \
  -H 'Content-Type:multipart/form-data' \
  -F "llm=mistralai/Ministral-3-14B-Reasoning-2512;type=text/plain" \
  -F "user_input=The MPON sends the dismissal to the MPOO.;type=text/plain" \
  -F "system_prompt=Return the list of tasks.;type=text/plain" \
  -F "format=false;type=text/plain"
```

---
