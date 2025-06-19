use sqlx::postgres::PgPoolOptions;

use timescale_example::read;

#[tokio::main]
async fn main() -> Result<(), sqlx::Error> {
    env_logger::Builder::from_env(env_logger::Env::default().default_filter_or("info")).init();

    let pool = PgPoolOptions::new()
        .max_connections(1)
        .connect(&std::env::var("DATABASE_URL").unwrap())
        .await?;

    sqlx::migrate!().run(&pool).await?;

    let results = read(&pool).await?;

    log::info!("{}", results.len());

    Ok(())
}
