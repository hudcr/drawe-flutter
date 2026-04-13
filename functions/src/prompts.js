const PROMPTS = [
  "a confused penguin",
  "a haunted toaster",
  "a cat riding a bicycle",
  "a dragon eating pizza",
  "a robot gardening",
  "a fish driving a car",
  "a sleeping volcano",
  "a dancing cactus",
  "a wizard doing laundry",
  "a dog on a skateboard",
  "a cloud with sunglasses",
  "a snail racing",
  "an elephant in a bathtub",
  "a ghost shopping",
  "a bear playing guitar",
  "the sun and moon arguing",
  "a sandwich with legs",
  "a frog in a top hat",
  "a spaceship eating tacos",
  "a dinosaur at a desk job",
  "a mermaid doing taxes",
  "a knight at a drive-thru",
  "a superhero napping",
  "a pirate using GPS",
  "a very tiny mountain",
  "your professor",
  "the last thing you ate",
  "a really bad car",
  "something you'd find at walmart",
  "the meaning of life",
  "a tree reading a book",
  "a banana thinking deeply",
  "a sneaky flamingo",
  // add more later
];

function getRandomPrompt(exclude = []) {
  const available = PROMPTS.filter((p) => !exclude.includes(p));
  const pool = available.length > 0 ? available : PROMPTS;
  return pool[Math.floor(Math.random() * pool.length)];
}

module.exports = { PROMPTS, getRandomPrompt };
