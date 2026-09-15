import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import { EMBEDDING_DIM, noteEmbeddingText, vectorsFromJinaResponse } from "./wyn.ts";

Deno.test("noteEmbeddingText concatena titolo e punti chiave, scarta i vuoti", () => {
  assertEquals(
    noteEmbeddingText(" Titolo ", ["primo", "  ", "secondo "]),
    "Titolo\nprimo\nsecondo",
  );
});

Deno.test("noteEmbeddingText con soli punti chiave", () => {
  assertEquals(noteEmbeddingText("", ["a"]), "a");
});

function vec(fill: number): number[] {
  return new Array(EMBEDDING_DIM).fill(fill);
}

Deno.test("vectorsFromJinaResponse: risposta in ordine", () => {
  const data = {
    data: [
      { embedding: vec(0.1), index: 0 },
      { embedding: vec(0.2), index: 1 },
    ],
  };
  assertEquals(vectorsFromJinaResponse(data, 2), [vec(0.1), vec(0.2)]);
});

Deno.test("vectorsFromJinaResponse: index in disordine viene riordinato", () => {
  const data = {
    data: [
      { embedding: vec(0.2), index: 1 },
      { embedding: vec(0.1), index: 0 },
    ],
  };
  assertEquals(vectorsFromJinaResponse(data, 2), [vec(0.1), vec(0.2)]);
});

Deno.test("vectorsFromJinaResponse: numero di elementi errato lancia", () => {
  const data = { data: [{ embedding: vec(0.1), index: 0 }] };
  assertThrows(() => vectorsFromJinaResponse(data, 2));
});

Deno.test("vectorsFromJinaResponse: embedding non array lancia", () => {
  const data = { data: [{ embedding: "non-array", index: 0 }] };
  assertThrows(() => vectorsFromJinaResponse(data, 1));
});

Deno.test("vectorsFromJinaResponse: dimensione errata lancia", () => {
  const data = { data: [{ embedding: [0.1, 0.2], index: 0 }] };
  assertThrows(() => vectorsFromJinaResponse(data, 1));
});

Deno.test("vectorsFromJinaResponse: index duplicato lancia", () => {
  const data = {
    data: [
      { embedding: vec(0.1), index: 0 },
      { embedding: vec(0.2), index: 0 },
    ],
  };
  assertThrows(() => vectorsFromJinaResponse(data, 2));
});

Deno.test("vectorsFromJinaResponse: index fuori range lancia", () => {
  const data = {
    data: [
      { embedding: vec(0.1), index: 0 },
      { embedding: vec(0.2), index: 5 },
    ],
  };
  assertThrows(() => vectorsFromJinaResponse(data, 2));
});

Deno.test("vectorsFromJinaResponse: index non intero lancia", () => {
  const data = {
    data: [
      { embedding: vec(0.1), index: 0 },
      { embedding: vec(0.2), index: 1.5 },
    ],
  };
  assertThrows(() => vectorsFromJinaResponse(data, 2));
});
