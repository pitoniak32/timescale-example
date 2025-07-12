```
helm template ./ --set-string=image.name="timescale/timescaledb",image.tag="latest-pg17"
```