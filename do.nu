export def "bundle all" [] {
    let file_sets = glob *.file-set.json | each { bundle file-set $in } | str join ((char newline) + (char newline))

    $"(open --raw PROMPT.md)

($file_sets | lines | first 1000000 | str join (char newline))

And finally, here is a **restatement** of the original request, so that you can get reacquainted with the objective after
having seen all the context.

(open --raw PROMPT.md)
" | str replace --all '/*
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
 */' "" | save --force bundle.txt
}

export def ask-gemini [] {
    let r = gemini-generate (open --raw bundle.txt)
    $r | to json | stash json
    $r.candidates.0.content.parts.0.text | stash md
}

export def ask-gemini-thinking [] {
    let r = gemini-generate-thinking (open --raw bundle.txt)
    $r | to json | stash json
    $r.candidates.0.content.parts.0.text | stash md
}

export def count-tokens [] {
    let r = gemini-count-tokens (open --raw bundle.txt)
    $r | to json | stash json
}

export def gemini-generate [prompt] {
    let url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" + $env.GEMINI_API_KEY
    let body = { contents: [ { parts: [ { text: $prompt } ] } ] } | to json
    http post --content-type application/json $url $body
}

export def gemini-generate-thinking [prompt] {
    let url = "https://generativelanguage.googleapis.com/v1alpha/models/gemini-2.0-flash-thinking-exp:generateContent?key=" + $env.GEMINI_API_KEY
    let body = { contents: [ { parts: [ { text: $prompt } ] } ] } | to json
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
