curl -X POST http://localhost:9297/generic/ \
-H 'Content-Type:multipart/form-data' \
-F "llm=gemini-2.5-flash-lite;type=text/plain" \
-F "user_input=The MPON sends the dismissal to the MPOO. The MPOO reviews the dismissal.;type=text/plain" \
-F "system_prompt=You are an expert in BPMN modelling. Return the list of tasks from provided process description.;type=text/plain" \
-F "format=false;type=text/plain"
