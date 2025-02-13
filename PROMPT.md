# iceberg

I want to create a new `iceberg-playground` repository where I explore and learn Apache Iceberg library.

This repository will be in my typical `-playground` repository style. I've attached the README files for all of my many playground
repositories. Please study them carefully to grok my style, tone, preference for concept focus, attention to
detail, sympathy for sweating the details, and overall highly edited content.

I've also attached much of the source of the Iceberg codebase, specifically the `api/`, `data/` and `parquet/` subprojects. Study
these in detail to grok what is possible with Iceberg, what is typical, and the exact incantations of code to make an
application backed by Iceberg tables. I've also attached the core docs.

I've also attached my `hibernate-playground` for code reference. This is of similar scope and breadth as what I want with
Iceberg.

I want you to generate the README files and the Java code for a new `iceberg-playground` repository. This is a tall task because I'm not
going to specify exactly what I want. You must infer a literal, well-described, well "instructed" (a la step by step
instructions) and sample input/output, README files as if the playground subprojects were fully implemented. This type
of development should remind you of Test Driven Development (TDD). In a way, it's README Driven Development. Or, "write
the memo" before building the product. After you've written each README file, ALSO actually implement the code. I only
want the core code, not any of the Gradle crud. For each subproject implement a single-file Java program with a main
method that does the job. You can use inner classes as much as you need. Do the main methods take some argument like
"append", "init", "delete", etc? The code should encapsulate what the README described and be functional. This is
designed much like a technical book plus accompanying code (Oreilly, No Starch Press etc,).

Because Iceberg is a rich library, I expect I'll want at least two (maybe up to 5) subprojects. I always need a "basic"
type subproject where I zero in on truly foundational concepts (a la "drill to the core", no distractions, no accidental complexity).
Sometimes there are multiple core concepts that can each take their own subproject.

Next, I like to engage with the tech with intermediate concepts. Is there a later lifecycle of the tech/data? Are there
obvious applications of the tech? Obvious sore points? Make subprojects as needed.

Some notes to remember:

* The root README is a brief index of the subprojects
* Each subproject has its own README
* Each subproject has a laser tight focus on a concept
* Intermediate subprojects always build off of and depend on concepts in the basic subprojects
* There are no hard dependencies AT ALL between subprojects. Each subproject is like a standalone repo
* Each subproject has verbatim instructions for building and running the subproject
* Each subproject conveys some "show don't tell" aspect, usually by printing output from the program
* I expect you to output the literal content. Never omit any content with an "..." or anything like that.
* Do not feel afraid of being verbose. Do what is necessary. I like exposition. I like names.
* I want to use Parquet as the backing file format.
* I don't want to use much of any of the Hadoop ecosystem  

Come up with a plan for the story and the core tech that the subprojects will cover. Defend and oppose your strategy.
Explain specific parts of the docs and source code inspired you to pick the subprojects you did. I need to be able to
audit this rationale so that I can ensure it's not a copycat of something that already exists. 

Then execute the strategy by writing immaculate README and Java code files. You need to do a good job so that I can take over and be
successful. I will edit for clarity and some correctness, but it's paramount that you establish a solid foundation.

Ultimately, I'm interested in learning Iceberg and implementing real-world production grade solutions with it in the
enterprise. I need to build a solid foundation of knowledge. And I need to learn by doing. Deliver on that premise with
complete content.

CRITICAL REMINDER: I've tried this with you a few times. You have a tendency to suggest a few subprojects, but then
only implement the 'basic' one. I need you to implement ALL of them. Never write the "END OF FILE" convention stuff even 
if you feel compelled to. That just makes you confused.
