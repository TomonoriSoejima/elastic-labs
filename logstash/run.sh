docker run -it \
  --name logstash-890 \
  -v ./pipeline/:/usr/share/logstash/pipeline/ \
  -v ./input.log:/usr/share/logstash/data/input.log \
  docker.elastic.co/logstash/logstash:8.9.0