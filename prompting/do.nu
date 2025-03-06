export def bundle [] {
    let prompt_file = "prompts/SCAFFOLD_WRITE_AND_READ.md"
    let file_sets_files = [
        "file-sets/api.file-set.json"
        "file-sets/data.file-set.json"
        "file-sets/docs.file-set.json"
        "file-sets/personal.file-set.json"
    ]

    let prompt = open --raw $prompt_file
    let file_sets = $file_sets_files | each { bundle file-set $in } | str join ((char newline) + (char newline)) | strip-license

    $"($prompt)

($file_sets)

And finally, here is a **restatement** of the original request, so that you can get reacquainted with the objective after
having seen all the context.

($prompt)
" | save --force bundle.txt
}

def strip-license [] {
    $in | str replace --all '/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */' ""
}

export def ask-gemini [] {
    let r = gemini-generate (open --raw bundle.txt)
    cd generated
    $r | to json | stash json
    $r.candidates.0.content.parts.0.text | stash md
}

export def count-tokens [] {
    let r = gemini-count-tokens (open --raw bundle.txt)
    cd generated
    $r | to json | stash json
}

export def gemini-url [] {
    # Flash 2.0
    # "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" + $env.GEMINI_API_KEY

    # Flash 2.0 Thinking (experimental)
    "https://generativelanguage.googleapis.com/v1alpha/models/gemini-2.0-flash-thinking-exp:generateContent?key=" + $env.GEMINI_API_KEY

    # 2.0 Pro (experimental)
    # "https://generativelanguage.googleapis.com/v1alpha/models/gemini-2.0-pro-exp-02-05:generateContent?key=" + $env.GEMINI_API_KEY
}

export def gemini-generate [prompt] {
    let url = gemini-url
    let body = {
        contents: [ { parts: [ { text: $prompt } ] } ]
        # generationConfig: { temperature: 1.0 }
    } | to json
    http post --content-type application/json $url $body
}

export def gemini-count-tokens [prompt] {
    let url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:countTokens?key=" + $env.GEMINI_API_KEY
    let body = { contents: [ { parts: [ { text: $prompt } ] } ] } | to json
    http post --content-type application/json $url $body
}

# Save the input to a file with a conventional name based on the current date and time.
# For example,
#
#     get-weather | to json | stash json
#
# Would create the file `2025-02-13_10-31-23.json` with the contents of whatever was piped into it
#
export def stash [extension]: [string -> nothing] {
    let date = date now | format date "%Y-%m-%d_%H-%M-%S"
    let filename = $date + "." + $extension
    $in | save $filename
}

export def my-repos-with-gradle [] {
    cd ~/repos/personal
    # Note: I'm excluding kafka-playground because it's just too huge, even though it is my favorite. It might even
    # skew the LLM in a bad way so let's ignore it. I'm also excluding a selection of other repositories to save more on
    # the context limit. I'm overflowing the 1 million context limit by a bit.
    let exclude = [
        "kafka-playground"
        "grpc-playground"
        "antlr-playground"
        "picocli-playground"
        "spock-playground"
        "testng-playground"
        "open-rewrite-playground"
        "jooq-playground"
        "http-client-server-playground"
        "jmeter-playground"
        "java-foreign-function-and-memory-api-playground"
    ]
    let opts = $exclude | each { |it| [--exclude $it] } | flatten

    let repos = fd --type directory --glob "*-playground" --exact-depth 1 ...$opts
    let repos_with_gradle = $repos | where { |dir|
        cd $dir
        let found = fd gradlew | length
        # My 'fd' wrapper mistakenly returns a list of an empty string result when it
        # really should return an empty list. So we need to check for greater than 1 instead of 0.
        $found > 1
    }

    $repos_with_gradle
}

export def files-of-interest [repo] {
    cd ~/repos/personal
    cd $repo

    let exclude_patterns = [
        '*.jar'
        'gradlew*'
        gradle-wrapper.properties
        '*.jsonl'
        start-kafka.sh
        graphiql.css
        package-lock.json
    ]

    let opts = $exclude_patterns | each { |it| [--exclude $it] } | flatten

    fd --type file ...$opts | where ($it | is-text-file)
}

export def full-file-list [] {
    let repos = my-repos-with-gradle
    let files = $repos | each { |repo|
        files-of-interest $repo | each { |it| $repo | path join $it }
    } | flatten
    $files
}

export def size-by-project [] {
    let repos = my-repos-with-gradle
    let sized_repos = $repos | par-each { |repo|
        cd ~/repos/personal
        cd $repo
        let files = files-of-interest $repo
        let content = $files | each { |it| open --raw $it } | str join (char newline)
        let wc = $content | str stats | get words
        let tokens = $content | token-count | into int
        { repo: $repo, size: $wc tokens: $tokens }
    }

    $sized_repos | sort-by --reverse tokens
}
