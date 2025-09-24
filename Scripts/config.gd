extends Node

const DEV_MODE : bool = false;

const SONG_MODE : bool = true if DEV_MODE else false;
const RECORDING_MODE : bool = true if DEV_MODE else false;
const SONG : int = 15;
const START_TIME : float = 0 if DEV_MODE else 0;
const GAME_SPEED : float = 1.0 if DEV_MODE else 1.0;
const BPM : int = 500;
const BPM_MULTIPLIER : int = BPM / 14.5;
