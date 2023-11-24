// Bind some values
let age = 1;
let name = "Monkey";
let result = 10 * (20 / 2);
let myArray = [1, 2, 3, 4];
let myHash = {"name": "Monkey", "size": 2};

// Accessing element
myArray[0];
myHash["name"];

// Bind function
let add = fn(a, b) {return a + b; };

// Implicit return value
let add' = fn(a, b) {a + b; };

// calling a function
add(1, 3);

// higher order functions
let twice = fn(f, x) {
	return f(f(x));
};

let addTwo = fn(x) {
	return x + 2;
};

// Function used as other values is a feature called "first class functions"
twice(addTwo, 2);
