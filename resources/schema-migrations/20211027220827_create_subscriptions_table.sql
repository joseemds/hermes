CREATE TABLE IF NOT EXISTS subscriptions(
	id uuid PRIMARY KEY NOT NULL,
	email TEXT NOT NULL UNIQUE,
	name TEXT NOT NULL,
	subscribed_at timestamptz NOT NULL
)

