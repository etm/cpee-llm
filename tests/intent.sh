curl -X POST http://localhost:9297/intent/ \
-H 'Content-Type:multipart/form-data' \
-F "user_input=How manu tasks are in the model.;type=text/plain" \
-F "llm=gemini-2.5-flash-lite;type=text/plain"
