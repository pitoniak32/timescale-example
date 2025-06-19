create new migration:
```bash
sqlx migrate add <migration name>
```

TODO: 
- [X] add queries for timescale metrics
- [ ] add grafana user with read only permissions
- [ ] persist data in a volume for grafana to avoid losing dashboards
- [ ] add queries for continuous aggregate in grafana