```
helm template ./ --set-string=image.name="timescale/timescaledb",image.tag="latest-pg17"
```

linting:
```
helm lint -f timescale-1.yaml --set-string=image.name="timescale/timescaledb",image.tag="latest-pg17"
```

```
helm upgrade --install timescale-db-1 ./ -f timescale-1.yaml --set-string=image.name="timescale/timescaledb",image.tag="latest-pg17"
```

```
helm upgrade --install timescale-db-2 ./ -f timescale-2.yaml --set-string=image.name="timescale/timescaledb",image.tag="latest-pg17"
```