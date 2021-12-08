import { mtrim } from "js-trim-multiline-string";

export const trimlog = (log) => console.log(mtrim(`${log}`));

export const sleep = (ms) => {
  return new Promise((resolve) => setTimeout(resolve, ms));
};
