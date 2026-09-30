/** Injectable time source. Server code reads the time only through `deps.clock` so tests can move it. */
export interface Clock {
  now(): Date;
}

export const systemClock: Clock = {
  now: () => new Date(),
};
