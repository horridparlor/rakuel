extends Node

const DEV_MODE : bool = false;

const SONG_MODE : bool = true if DEV_MODE else false;
const RECORDING_MODE : bool = true if DEV_MODE else false;
const SONG : int = 8;
const START_TIME : float = 0 if DEV_MODE else 0;
