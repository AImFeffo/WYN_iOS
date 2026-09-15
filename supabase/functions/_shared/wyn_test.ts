import { assertEquals } from "jsr:@std/assert@1";
import { noteEmbeddingText } from "./wyn.ts";

Deno.test("noteEmbeddingText concatena titolo e punti chiave, scarta i vuoti", () => {
  assertEquals(
    noteEmbeddingText(" Titolo ", ["primo", "  ", "secondo "]),
    "Titolo\nprimo\nsecondo",
  );
});

Deno.test("noteEmbeddingText con soli punti chiave", () => {
  assertEquals(noteEmbeddingText("", ["a"]), "a");
});
