use chrono::{DateTime, Utc};
use sqlx::{FromRow, postgres::types::PgInterval};
use uuid::Uuid;

#[derive(Debug, FromRow)]
pub struct RepositoryRow {
    pub id: i32,
    pub name: String,
    pub org_id: Uuid,
}

#[derive(Debug, FromRow)]
pub struct WorkflowRunRow {
    pub time: DateTime<Utc>,
    pub workflow_name: String,
    pub repository_id: i32,
    pub duration: PgInterval,
}

pub async fn read(pool: &sqlx::PgPool) -> Result<Vec<WorkflowRunRow>, sqlx::Error> {
    let results = sqlx::query_as!(
        WorkflowRunRow,
        r#"
        SELECT time, workflow_name, repository_id, duration
        FROM workflow_runs
    "#
    )
    .fetch_all(pool)
    .await?;

    Ok(results)
}

pub async fn create_repository(
    repo_id: i32,
    name: &str,
    org_id: &Uuid,
    pool: &sqlx::PgPool,
) -> Result<(), sqlx::Error> {
    // let query = r#"
    // BEGIN
    //   IF NOT EXISTS (SELECT * FROM github_repository WHERE id = $1)
    //   BEGIN
    //     INSERT INTO github_repository (id, name) VALUES ($1, $2)
    //   END
    // END
    // "#;

    let query = "INSERT INTO repositories (id, name, org_id) VALUES ($1, $2, $3)";

    log::info!(
        "Inserting id = {}, name = {}, org = {}!",
        repo_id,
        name,
        org_id
    );

    sqlx::query(query)
        .bind(repo_id)
        .bind(name)
        .bind(org_id)
        .execute(pool)
        .await?;

    Ok(())
}

pub async fn create_workflow_run(
    run: &WorkflowRunRow,
    pool: &sqlx::PgPool,
) -> Result<(), sqlx::Error> {
    let query = "INSERT INTO workflow_runs (time, workflow_name, repository_id, duration) VALUES ($1, $2, $3, $4)";

    sqlx::query(query)
        .bind(run.time)
        .bind(&run.workflow_name)
        .bind(run.repository_id)
        .bind(run.duration)
        .execute(pool)
        .await?;

    Ok(())
}
