const HERDR_ENV_PREFIX = "HERDR_";

/**
 * Headless subagents are not running in the parent's Herdr pane. Letting them
 * inherit Herdr's caller context causes native hooks (or the agent itself) to
 * report against and control the parent pane.
 */
export function withoutHerdrEnvironment(
  environment: NodeJS.ProcessEnv = process.env,
) {
  return Object.fromEntries(
    Object.entries(environment).filter(
      ([name]) => !name.startsWith(HERDR_ENV_PREFIX),
    ),
  );
}

export function isInsideHerdr(environment: NodeJS.ProcessEnv = process.env) {
  return (
    environment.HERDR_ENV === "1" &&
    typeof environment.HERDR_PANE_ID === "string" &&
    environment.HERDR_PANE_ID.length > 0 &&
    typeof environment.HERDR_SOCKET_PATH === "string" &&
    environment.HERDR_SOCKET_PATH.length > 0
  );
}
