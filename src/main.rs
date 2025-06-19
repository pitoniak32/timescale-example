use sqlx::{
    FromRow,
    postgres::PgPoolOptions,
    types::chrono::{DateTime, Utc},
};

#[derive(Debug, Default, FromRow)]
pub struct WorkflowRun {
    pub time: DateTime<Utc>,
    pub workflow_name: String,
    pub repository_name: String,
    pub duration: i32,
}

async fn read(pool: &sqlx::PgPool) -> Result<Vec<WorkflowRun>, sqlx::Error> {
    let results = sqlx::query_as::<_, WorkflowRun>(
        "SELECT time, workflow_name, repository_name, duration FROM workflow_runs",
    )
    .fetch_all(pool)
    .await?;

    Ok(results)
}

async fn create(run: &WorkflowRun, pool: &sqlx::PgPool) -> Result<(), sqlx::Error> {
    let query = "INSERT INTO workflow_runs (time, workflow_name, repository_name, duration) VALUES ($1, $2, $3, $4)";

    sqlx::query(query)
        .bind(Utc::now())
        .bind(&run.workflow_name)
        .bind(&run.repository_name)
        .bind(run.duration)
        .execute(pool)
        .await?;

    Ok(())
}

#[tokio::main]
async fn main() -> Result<(), sqlx::Error> {
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info")).init();

    let pool = PgPoolOptions::new()
        .max_connections(1)
        .connect(&std::env::var("DATABASE_URL").unwrap())
        .await?;

    sqlx::migrate!("./migrations").run(&pool).await?;

    let run = WorkflowRun {
        time: Utc::now(),
        workflow_name: "main-cd".to_owned(),
        repository_name: "timescale-example".to_owned(),
        duration: 10000,
    };

    create(&run, &pool).await?;

    let results = read(&pool).await?;

    log::info!("{results:#?}");

    Ok(())
}
