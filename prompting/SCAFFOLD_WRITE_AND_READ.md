# scaffolding a 'write and read' Apache Iceberg application

I want to create a new `iceberg-playground` repository where I explore and learn Apache Iceberg family of libraries.

This repository will be in my typical `-playground` repository style. I've attached many of my playground
repositories. Please study them carefully to grok my style. In my writing, try to grok my tone, preference for concept
focus, tight linear progression, linking preference, sympathy for sweating the details, and overall highly edited content.
In my code, try to grok my use of local variables, top-down tutorial-style preference, explaining the "why" in comments,
explaining API quirks in the comments, lack of abstraction (a must for tutorials), and absolute aversion to bringing in
accidental complexity that takes away from the core concept. These repositories are not for production, they're for
teaching and reference. 

I've also attached much of the source of the Iceberg codebase, specifically the `api/`, `data/` and `parquet/` subprojects. Study
these in detail to grok what is possible with Iceberg, what is typical, and the exact incantations of code to make an
application backed by Iceberg tables. I've also attached the core docs.

To start, I want you to generate a complete sub-project called `write-and-read`, which serves as an essential foundation
for using a table technology like Iceberg. Obviously, we must write to and read from a table. 

This is somewhat of a tall task because I'm not going to specify exactly what I want. You must infer a lot of details.
It's especially important to get the README right because it informs the implementation. The README must be well-described,
well "instructed" (a la step by step instructions) and have sample input/output. Infer a perfect README file based on my
other README files, and combine it especially with the concept writing in the Iceberg docs (`docs/` file set). What
should the `write-and-read` subproject do to really teach the reader about literally writing and reading from an Iceberg
table and of course the incidental details of making the table, filling out necessary metadata, and so on.

Implement the actual code! This must have the `build.gradle.kts`, and other Gradle files EXCEPT the gradle wrapper
files (I'll do that, that's just noise). It must be a single-file Java program with a main method that does the job. You can use inner
classes as much as you need. Do the main methods take some argument like "append", "init", "delete", etc? The code should
encapsulate what the README described and be functional. This is designed much like a technical book plus accompanying
code (Oreilly, No Starch Press etc,).

Some other notes:

* I need a root README as well as the sub-project itself
* The subproject README has verbatim instructions for building and running the subproject
* The subproject README conveys some "show don't tell" aspect, usually by printing output from the program
* I expect you to output the literal content. Never omit any content with an "..." or anything like that.
* Do not feel afraid of being verbose. Do what is necessary. I like exposition. I like names.
* I want to use Parquet as the backing file format.
* I don't want to use much of any of the Hadoop ecosystem  

Come up with a plan for the story and the core tech that the subproject will cover. Defend and oppose your strategy.
Explain specific parts of the docs and source code inspired you to pick the subprojects you did. I need to be able to
audit this rationale so that I can ensure it's not a copycat of something that already exists. 

Then execute the strategy by writing the files out in complete detail. Before you end, enumerate the files that you
created as a way to audit that you actually scaffolded an entire, compilable, runnable, coherent project.
You need to do a good job so that I can take over and be successful. I will edit for clarity and some correctness, but
it's paramount that you establish a solid foundation.

Ultimately, I'm interested in learning Iceberg and implementing real-world production grade solutions with it in the
enterprise. I need to build a solid foundation of knowledge. And I need to learn by doing. Deliver on that premise with
complete content.
