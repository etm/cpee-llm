curl -X POST http://localhost:9297/generic/ \
-H 'Content-Type:multipart/form-data' \
-F "llm=gemini-2.5-flash-lite;type=text/plain" \
-F "user_input=How many fruit has the boy. Just the number;type=text/plain" \
-F "system_prompt=Analyse the document;type=text/plain" \
-F "format=false;type=text/plain" \
-F "document=@doc.txt;type=text/plain"
