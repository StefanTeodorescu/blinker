var q = document.location.search;
if (q.startsWith('?')) q = q.substring(1);
var uuid = decodeURIComponent((q.split('&').filter(function (param) { return param.startsWith('uuid='); }).slice(-1)[0]||'').substring(5));

var surveyJSON =
{
 pages: [
  {
   name: "ctf-background",
   questions: [
    {
     type: "html",
     html: "The survey has two main parts. First, you will be asked a number of questions on your background and experience with CTFs. Then in the second half, you will be shown some of the techniques I have devised and asked to give feedback on them.\n\nOnly questions marked with an asterisk are mandatory.",
     name: "intro-html"
    },
    {
     type: "radiogroup",
     name: "has-experience-solving",
     title: "Do you have any experience solving CTF-style challenges?",
     isRequired: true,
     choices: [
      {
       value: "yes",
       text: "Yes"
      },
      {
       value: "no",
       text: "No"
      }
     ]
    },
    {
     type: "radiogroup",
     name: "ctftime-team",
     visible: false,
     visibleIf: "{has-experience-solving}='yes'",
     title: "...as part of a team registered on CTFtime.org?",
     isRequired: true,
     choices: [
      {
       value: "yes",
       text: "Yes"
      },
      {
       value: "no",
       text: "No"
      }
     ]
    },
    {
     type: "text",
     name: "ctftime-team-name",
     visible: false,
     visibleIf: "({ctftime-team}='yes' and {has-experience-solving}='yes')",
     title: "Which team is that?",
     size: "100"
    },
    {
     type: "radiogroup",
     name: "ctftime-team-score",
     visible: false,
     visibleIf: "({ctftime-team}='yes' and {has-experience-solving}='yes')",
     title: "Roughly how many points did your team have on CTFtime.org in their best year?",
     choices: [
      ">1000",
      "501-1000",
      "301-500",
      "201-300",
      "101-200",
      "51-100",
      "0-50"
     ]
    },
    {
     type: "comment",
     name: "ctf-experience-other",
     visible: false,
     visibleIf: "({ctftime-team}='no' and {has-experience-solving}='yes')",
     title: "Please briefly explain the nature of your experience with CTF-style challenges."
    },
    {
     type: "radiogroup",
     name: "how-many-ctfs",
     visible: false,
     visibleIf: "{has-experience-solving}='yes'",
     title: "Roughly how many CTFs have you taken part in?",
     choices: [
      ">20",
      "11-20",
      "6-10",
      "3-5",
      "2",
      "1",
      "0"
     ]
    },
    {
     type: "checkbox",
     name: "challenge-categories-solving",
     visible: false,
     visibleIf: "{has-experience-solving}='yes'",
     title: "Which challenge categories would you say you have reasonable familiarity with (in terms of solving challenges)?",
     choices: [
      {
       value: "web",
       text: "Web"
      },
      {
       value: "crypto",
       text: "Crypto"
      },
      {
       value: "pwn",
       text: "Pwn (Binary exploitation)"
      },
      {
       value: "reverse",
       text: "Reverse (Reverse engineering)"
      },
      {
       value: "forensics",
       text: "Forensics"
      },
      {
       value: "trivia",
       text: "Trivia"
      }
     ]
    },
    {
     type: "radiogroup",
     name: "has-experience-authoring",
     title: "Do you have experience setting CTF-style challenges?",
     isRequired: true,
     choices: [
      {
       value: "yes",
       text: "Yes"
      },
      {
       value: "no",
       text: "No"
      }
     ]
    },
    {
     type: "checkbox",
     name: "challenge-categories-authoring",
     visible: false,
     visibleIf: "{has-experience-authoring}='yes'",
     title: "Which challenge categories would you say you have reasonable familiarity with (in terms of setting challenges)?",
     choices: [
      {
       value: "web",
       text: "Web"
      },
      {
       value: "crypto",
       text: "Crypto"
      },
      {
       value: "pwn",
       text: "Pwn (Binary exploitation)"
      },
      {
       value: "reverse",
       text: "Reverse (Reverse engineering)"
      },
      {
       value: "forensics",
       text: "Forensics"
      },
      {
       value: "trivia",
       text: "Trivia"
      }
     ]
    }
   ],
   title: "Your CTF background"
  },
  {
   name: "authoring-ctf",
   questions: [
    {
     type: "radiogroup",
     name: "has-experience-authoring-ctfs",
     visible: false,
     visibleIf: "{has-experience-authoring}='yes'",
     title: "Do you have experience setting problems for CTF competitions?",
     isRequired: true,
     choices: [
      {
       value: "yes",
       text: "Yes"
      },
      {
       value: "no",
       text: "No"
      }
     ]
    },
    {
     type: "radiogroup",
     name: "how-many-authored-ctfs",
     visible: false,
     visibleIf: "{has-experience-authoring-ctfs}='yes'",
     title: "Roughly how many challenges have you designed for use in CTF competitions?",
     choices: [
      ">10",
      "6-10",
      "3-5",
      "2",
      "1",
      "0"
     ]
    },
    {
     type: "radiogroup",
     name: "how-many-used-ctfs",
     visible: false,
     visibleIf: "{has-experience-authoring-ctfs}='yes'",
     title: "Roughly how many of your problems have been used in CTFs registered on CTFtime.org?",
     choices: [
      ">10",
      "6-10",
      "3-5",
      "2",
      "1",
      "0"
     ]
    },
    {
     type: "radiogroup",
     name: "how-many-reached-ctfs",
     visible: false,
     visibleIf: "{has-experience-authoring-ctfs}='yes'",
     title: "Roughly how many people have your challenges reached (via CTF competitions)?",
     choices: [
      ">1000",
      "101-1000",
      "11-100",
      "1-10"
     ]
    },
    {
     type: "radiogroup",
     name: "how-many-solved-ctfs",
     visible: false,
     visibleIf: "{has-experience-authoring-ctfs}='yes'",
     title: "Roughly how many people solved your challenges (that you are aware of)?",
     choices: [
      ">1000",
      "101-1000",
      "11-100",
      "1-10"
     ]
    },
    {
     type: "radiogroup",
     name: "how-many-writeups-ctfs",
     visible: false,
     visibleIf: "{has-experience-authoring-ctfs}='yes'",
     title: "Roughly how many of your challenges have had write-ups posted online by others (that you are aware of)?",
     choices: [
      ">10",
      "6-10",
      "3-5",
      "2",
      "1",
      "0"
     ]
    }
   ],
   title: "Setting problems for CTF competitions",
   visible: false,
   visibleIf: "{has-experience-authoring}='yes'"
  },
  {
   name: "authoring-academia",
   questions: [
    {
     type: "radiogroup",
     name: "has-experience-authoring-academia",
     visible: false,
     visibleIf: "{has-experience-authoring}='yes'",
     title: "Do you have experience using CTF-style problems for educational purposes in academia?",
     isRequired: true,
     choices: [
      {
       value: "yes",
       text: "Yes"
      },
      {
       value: "no",
       text: "No"
      }
     ]
    },
    {
     type: "radiogroup",
     name: "academic-role",
     visible: false,
     visibleIf: "{has-experience-authoring-academia}='yes'",
     title: "In what role did you acquire this experience?",
     hasOther: true,
     choices: [
      {
       value: "lecturer",
       text: "Lecturer"
      },
      {
       value: "guest-lecturer",
       text: "Guest lecturer"
      },
      {
       value: "ta",
       text: "Demonstrator / TA"
      }
     ],
     otherErrorText: "Please elaborate on your role.",
     otherText: "Other (please elaborate)"
    },
    {
     type: "radiogroup",
     name: "how-many-authored-academia",
     visible: false,
     visibleIf: "{has-experience-authoring-academia}='yes'",
     title: "Roughly how many challenges have you designed for use in an academic environment?",
     choices: [
      ">10",
      "6-10",
      "3-5",
      "2",
      "1"
     ]
    },
    {
     type: "radiogroup",
     name: "how-many-reached-academia",
     visible: false,
     visibleIf: "{has-experience-authoring-academia}='yes'",
     title: "Roughly how many students have your challenges reached?",
     choices: [
      ">1000",
      "101-1000",
      "11-100",
      "1-10"
     ]
    },
    {
     type: "radiogroup",
     name: "solver-percentage-academia",
     visible: false,
     visibleIf: "{has-experience-authoring-academia}='yes'",
     title: "Roughly what percentage of students manage to solve your problems on average?",
     choices: [
      {
       value: ">86",
       text: ">86%"
      },
      {
       value: "51-85",
       text: "51-85%"
      },
      {
       value: "20-50",
       text: "21-50%"
      },
      {
       value: "<20",
       text: "<20%"
      }
     ]
    },
    {
     type: "radiogroup",
     name: "mandatory-academia",
     visible: false,
     visibleIf: "{has-experience-authoring-academia}='yes'",
     title: "Were your challenges a mandatory part of the course?",
     choices: [
      {
       value: "graded",
       text: "Mandatory and graded."
      },
      {
       value: "not-graded",
       text: "Mandatory, but not graded."
      },
      {
       value: "optional",
       text: "Optional."
      }
     ]
    }
   ],
   title: "Using CTF problems in academia",
   visible: false,
   visibleIf: "{has-experience-authoring}='yes'"
  },
  {
   name: "authoring-other",
   questions: [
    {
     type: "radiogroup",
     name: "has-experience-authoring-other",
     visible: false,
     visibleIf: "{has-experience-authoring}='yes'",
     title: "Do you have experience using CTF-style problems for educational purposes outside of academia?",
     isRequired: true,
     choices: [
      {
       value: "yes",
       text: "Yes"
      },
      {
       value: "no",
       text: "No"
      }
     ]
    },
    {
     type: "radiogroup",
     name: "other-setting",
     visible: false,
     visibleIf: "{has-experience-authoring-other}='yes'",
     title: "In what setting did you acquire this experience?",
     hasOther: true,
     choices: [
      {
       value: "informal",
       text: "Informal"
      },
      {
       value: "commercial",
       text: "Commercial"
      }
     ],
     otherText: "Other (please elaborate)"
    },
    {
     type: "checkbox",
     name: "other-setting-students",
     visible: false,
     visibleIf: "({other-setting}='commercial' and {has-experience-authoring-other}='yes')",
     title: "Primarily which sectors do your students represent?",
     hasOther: true,
     choices: [
      {
       value: "tech",
       text: "IT/Technology"
      },
      {
       value: "defence",
       text: "Defence"
      },
      {
       value: "military",
       text: "Military"
      },
      {
       value: "consulting",
       text: "Consulting"
      },
      {
       value: "finance",
       text: "Finance"
      },
      {
       value: "government",
       text: "Government"
      }
     ],
     otherErrorText: "Please name which other sector you meant.",
     otherText: "Other (more than one allowed)"
    },
    {
     type: "radiogroup",
     name: "how-many-authored-other",
     visible: false,
     visibleIf: "{has-experience-authoring-other}='yes'",
     title: "Roughly how many challenges have you designed for educational purposes?",
     choices: [
      ">10",
      "6-10",
      "3-5",
      "2",
      "1"
     ]
    },
    {
     type: "radiogroup",
     name: "how-many-reached-other",
     visible: false,
     visibleIf: "{has-experience-authoring-other}='yes'",
     title: "Roughly how many students have your challenges reached?",
     choices: [
      ">1000",
      "101-1000",
      "11-100",
      "1-10"
     ]
    },
    {
     type: "radiogroup",
     name: "solver-percentage-other",
     visible: false,
     visibleIf: "{has-experience-authoring-other}='yes'",
     title: "Roughly what percentage of students manage to solve your problems on average?",
     choices: [
      {
       value: ">86",
       text: ">86%"
      },
      {
       value: "51-85",
       text: "51-85%"
      },
      {
       value: "20-50",
       text: "21-50%"
      },
      {
       value: "<20",
       text: "<20%"
      }
     ]
    }
   ],
   title: "Using CTF problems for educational purposes outside of academia",
   visible: false,
   visibleIf: "{has-experience-authoring}='yes'"
  },
  {
   name: "motivation",
   questions: [
    {
     type: "html",
     html: "<p>My work is motivated by the problem of cheating. In most CTFs, participants can easily share flags, or exploit/solution scripts, and will get away with this. There is <a href=\"https://www.usenix.org/system/files/conference/3gse15/3gse15-burket.pdf\">some evidence</a> that this problem could be just as severe in reality as it sounds. We can also expect it to be even worse in primarily educational settings, where there are no incentives against helping other participants.</p>\n\n<p>The tools I have developed may potentially be useful for other purposes, but their main design goal was to make collusion between participants in a CTF more difficult.</p>",
     name: "motivation-html"
    },
    {
     type: "radiogroup",
     name: "encountered-collusion",
     title: "Have you ever encountered some form of collusion (e.g. sharing flags, exploits, hints, or solution scripts) in a CTF you participated in or helped organise? [Only consider cases that were in violation of the rules of the competition.]",
     choices: [
      {
       value: "yes",
       text: "Yes"
      },
      {
       value: "no",
       text: "No"
      }
     ]
    },
    {
     type: "rating",
     name: "ctfs-do-enough",
     title: "Please choose whether you agree with the following statement. In your opinion, the CTFs you are familiar with make an effort to stop collusion between participants.",
     rateValues: [
      {
       value: "1",
       text: "Strongly disagree"
      },
      {
       value: "2",
       text: "Somewhat disagree"
      },
      {
       value: "3",
       text: "Neutral"
      },
      {
       value: "4",
       text: "Somewhat agree"
      },
      {
       value: "5",
       text: "Strongly agree"
      }
     ]
    },
    {
     type: "rating",
     name: "ctfs-should-try-harder",
     title: "Please choose whether you agree with the following statement. In your opinion, the CTFs you are familiar with should try harder to stop collusion between participants.",
     rateValues: [
      {
       value: "1",
       text: "Strongly disagree"
      },
      {
       value: "2",
       text: "Somewhat disagree"
      },
      {
       value: "3",
       text: "Neutral"
      },
      {
       value: "4",
       text: "Somewhat agree"
      },
      {
       value: "5",
       text: "Strongly agree"
      }
     ]
    },
    {
     type: "rating",
     name: "ctfs-have-tools",
     title: "Please choose whether you agree with the following statement. In your opinion, CTF organisers have effective tools or methods readily available to them for combating collusion.",
     rateValues: [
      {
       value: "1",
       text: "Strongly disagree"
      },
      {
       value: "2",
       text: "Somewhat disagree"
      },
      {
       value: "3",
       text: "Neutral"
      },
      {
       value: "4",
       text: "Somewhat agree"
      },
      {
       value: "5",
       text: "Strongly agree"
      }
     ]
    }
   ],
   title: "Motivation",
   visible: false,
   visibleIf: "({has-experience-solving}='yes' or {has-experience-authoring}='yes')"
  },
  {
   name: "preliminaries",
   questions: [
    {
     type: "html",
     html: "<p>\nOn the next few pages you will see a summary of the techniques I have developed for automatically generating new instances of binary exploitation and reverse engineering challenges. Originally I was planning to work on other challenges types, such as crypto, web, and forensics as well. However, after more detailed analysis my opinion now is that crypto and web challenges are much less amenable to automatic generation. Forensics is somewhat better suited for automation, but is still not ideal.\n</p>\n\n<p>\nI base these claims on the following argument. In the case of a binary challenge (exploitation or reverse engineering), the challenge consists of a computer-generated artefact. The generation process is driven by input from a human author (the source code), but a considerable proportion of the output is not explicitly described in the input. In contrast, crypto challenges are the exact opposite: an abstract (quasi)mathematical concept is translated into just enough program code, usually in a high level language like Python, and the focus is not on the implementation, but the underlying idea. This setting arguably puts more focus on human intelligence and creativity, which are not things that I can replicate in a program <small>(and especially not things that can be replicated in the course of an undergraduate Computer Science dissertation)</small>.\n</p>\n\n<p>\nMoving to a practical level, let us contrast a buffer overflow and a SQL injection CTF challenge. In case of the buffer overflow vulnerability, there are many specific details that one needs to get right for a successful exploit, and changing some of these to produce a new buffer overflow challenge sounds plausible. For example, if the stack layout of the vulnerable function is perturbed somewhat, and different ROP gadgets are available, the exploit will be meaningfully and realistically different. But this approach does not translate naturally to the SQL injection challenge.\n</p>\n\n<p>\nOne candidate for the property of SQL injection challenges corresponding to stack layout in binary challenges could be HTTP parameter names, but those are usually human readable and depend on the application (a gift shop will have different fields on their web forms than a bulletin board for heavy metal fans). Other aspects of the vulnerability would be the types of quotes used in the underlying SQL query, or the set of allowed characters, but these only yield a very limited amount of variation, and might put solvability at risk.\n</p>\n\n<p>\nWe are forced to recognise that no straightforward opportunities for randomisation arise in the SQL injection scenario. Crypto challenges generally appear to behave quite similarly.\n</p>",
     name: "preliminaries-html"
    },
    {
     type: "radiogroup",
     choices: [
      {
       value: "yes",
       text: "Yes, it is mostly correct."
      },
      {
       value: "somewhat",
       text: "Somewhat. The conclusion is reasonable, but the argument is broken."
      },
      {
       value: "not-quite",
       text: "Not quite. There is some truth to it, but it is incomplete."
      },
      {
       value: "no",
       text: "No, it is incorrect or misses obvious facts."
      }
     ],
     name: "preliminaries-agree",
     title: "Do you agree with the conclusion I have reached above?"
    },
    {
     type: "comment",
     name: "preliminaries-feedback",
     title: "Please elaborate on your answer to the previous question. Confirmation, objections, ideas, questions, concerns, half-formed thoughts are all welcome."
    }
   ],
   title: "Preliminaries",
   visibleIf: "({has-experience-solving}='yes' or {has-experience-authoring}='yes')"
  },
  {
   name: "vgts",
   questions: [
    {
     type: "html",
     html: "<p>\nThe techniques I will describe are all aimed at introducing variation into binary exploitation/reverse engineering challenges during compilation. The idea is that challenge authors write C/C++ source code, optionally include some templatisation, and then compile with a custom LLVM-based compiler toolchain. The modified toolchain introduces variation into the output and therefore allows for producing a large number of different challenge binaries (challenge instances) from the same source code (challenge template). This would enable CTF organisers to give each participant a unique challenge instance with a unique flag and vulnerability, but which is still sufficiently similar to other instances to be called the same challenge.\n</p>\n\n<p>\nThis approach has its limitations. The most important ones are that the only \nsupported binaries are ELFs for x86_64 architectures, using the System-V ABI. However, none of these particular restrictions are a consequence of the approach, rather they are limitations of the current implementation. The only real limitation of the approach that I am aware of is that this forces challenge authors to implement their challenge in C/C++, and use an LLVM-based toolchain for compiling it. My opinion is that this restriction is not unreasonable, and a large percentage of challenges designed for most CTFs could benefit from taking advantage of this approach.\n</p>\n\n<p>\nMy hypothesis is that these techniques are useful for combating collusion. When each team has a different binary, with a different flag, the only ways they could collude are to</p>\n<ol>\n<li>share an exploit script that is resilient to this change, or</li>\n<li>explain the high level idea behind the solution and let the other team come up with their own exploit.</li>\n</ol>\n<p>Clearly both of these are possible, and so techniques like this cannot hope to completely eliminate collusion. However, I would argue that an imperfect solution attempt is still helpful, because it can make collusion more difficult and therefore less worthwhile.\n</p>\n\n<p>\nLater I will show a few examples of these techniques, but first I would like to ask for your general opinion on the topic.\n</p>",
     name: "vgts-html"
    },
    {
     type: "comment",
     name: "vgts-limitations",
     title: "Do you think there are other important limitations on the applicability of these techniques to real CTF challenges?"
    },
    {
     type: "radiogroup",
     name: "vgts-applicable",
     title: "Do you think you could use a system like this for binary exploitation or reverse engineering challenges you develop?",
     choices: [
      {
       value: "almost-always",
       text: "Almost always"
      },
      {
       value: "sometimes",
       text: "Sometimes"
      },
      {
       value: "almost-never",
       text: "Almost never"
      }
     ]
    },
    {
     type: "checkbox",
     name: "vgts-why-not",
     title: "Imagine that a system like this was freely available under a permissive open source license. Please tick any of the concerns below that might keep you from using it for challenges where it is applicable.",
     hasOther: true,
     choices: [
      {
       value: "complex",
       text: "It would make challenge development overly complex"
      },
      {
       value: "time-consuming",
       text: "It would be unreasonably time-consuming"
      },
      {
       value: "pointless",
       text: "It would be pointless"
      },
      {
       value: "resource-intensive",
       text: "It would be too resource-intensive"
      },
      {
       value: "quality",
       text: "It would harm the quality of the challenge"
      }
     ],
     otherText: "Other (please elaborate)"
    },
    {
     type: "comment",
     name: "vgts-feedback",
     title: "Do you have any other relevant thoughts, concerns, or questions?"
    }
   ],
   title: "Introducing variation into the compiler toolchain",
   visible: false,
   visibleIf: "({has-experience-solving}='yes' or {has-experience-authoring}='yes')"
  },
  {
   name: "chall",
   questions: [
    {
     type: "html",
     html: "<p>\nAll of the techniques can be utilised just by using the customised LLVM-based toolchain mentioned earlier, but for simplicity (and to allow integration into a framework I have created), challenges are described by a .chall file. These files are a mix between a declarative property description file and a Makefile-like build script. Under the hood, these challenge descriptor files are Ruby scripts written using the Rake (Ruby Make) DSL.\n</p>\n\n<p>\nHere is a simple example to give an idea of what a .chall file might look like, just in case you are not fluent in Ruby. I have annotated all parts of the file, but please do not get distracted by the details. The only thing to note is the <code>c_flags</code> bit.\n</p>\n\n<pre>\n# A line like this:\n# task :something =&gt; 'somefile'\n# corresponds to a phony target in a regular Makefile:\n# .PHONY: something\n# something: somefile\n\n# This challenge fits into the typical scenario where a binary is being run on a server, with its standard input/output connected \n# to a network socket, and participants have to exploit the vulnerability remotely.\nscenario 'stdio_socat'\n\n# The executable that will have to be run is called 'serial'\ntask :executable =&gt; 'serial'\n# The file called 'serial' should be made available to participants for download\ntask :handout =&gt; 'serial'\n# The instructions displayed to participants are generated at run time from the file called 'description.html.erb'\ntask :description =&gt; 'description.html.erb'\n\n# The file 'description.html.erb' is generated by running the Ruby code in the do-end block and capturing its standard output.\ngenerated_file 'description.html.erb' do\n  puts &lt;&lt;EOF\n&lt;a href=\"&lt;%= handout_url %&gt;\"&gt;This executable&lt;/a&gt; is running on the server (port #{BlinkerVars.socat_port}). Exploit it to read the contents of the file called &lt;code&gt;flag&lt;/code&gt;.\nEOF\nend\n\n# The next C/C++ compilation will use the following options\n# :stack_protector enables stack canaries, as with vanilla gcc/clang\n# :strip will remove symbols from the produced executable\n# the remaining options are part of the custom toolchain and will be introduced later\nc_flags :stack_protector =&gt; true, :strip =&gt; true,\n        :reorder_got_plt =&gt; true,\n        :reorder_plt =&gt; true,\n        :randomize_regs =&gt; true,\n        :randomize_branches =&gt; true,\n        :randomize_function_spacing =&gt; true,\n        :randomize_scheduling =&gt; true,\n        :reorder_functions =&gt; true,\n        :reorder_globals =&gt; true\n# The file 'serial' is produced by compiling the file 'serial.c' as C code\nc_compiled 'serial' =&gt; 'serial.c'\n</pre>",
     name: "chall-html"
    }
   ],
   title: "Challenge description format",
   visible: false,
   visibleIf: "({has-experience-solving}='yes' or {has-experience-authoring}='yes')"
  },
  {
   name: "gotplt",
   questions: [
    {
     type: "html",
     html: "<p>\nOne of the techniques seen in the previous example is <code>.got.plt</code>/<code>.plt</code> entry order randomisation. This is achieved by linking with a customised version of the LLVM linker, LLD. A simple .chall file containing the excerpt below can be used to demonstrate this technique.\n</p>\n\n<pre>\n# test.chall\n# ...\nc_flags :reorder_got_plt =&gt; true, :reorder_plt =&gt; true\nc_compiled 'test' =&gt; 'test.c'\n# ...\n</pre>\n\n<p>\n<code>test.c</code> contains a trivial <code>main</code> function that calls <code>puts</code> and <code>printf</code>. Two instances of this 'challenge' are now produced, these are <code>test1</code> and <code>test2</code>. Examining their (PLT)GOTs yields the following output.\n</p>\n\n<pre>\ngabor@part2-project:/tmp/demo$ readelf --relocs test1\n\nRelocation section '.rela.plt' at offset 0x3c0 contains 3 entries:\n  Offset          Info           Type           Sym. Value    Sym. Name + Addend\n000000202030  000300000007 R_X86_64_JUMP_SLO 0000000000201200 __libc_start_main@GLIBC_2.2.5 + 0\n000000202038  000100000007 R_X86_64_JUMP_SLO 00000000002011f0 puts@GLIBC_2.2.5 + 0\n000000202028  000200000007 R_X86_64_JUMP_SLO 0000000000201210 printf@GLIBC_2.2.5 + 0\n\ngabor@part2-project:/tmp/demo$ readelf --relocs test2\n\nRelocation section '.rela.plt' at offset 0x3c0 contains 3 entries:\n  Offset          Info           Type           Sym. Value    Sym. Name + Addend\n000000202038  000300000007 R_X86_64_JUMP_SLO 0000000000201200 __libc_start_main@GLIBC_2.2.5 + 0\n000000202030  000100000007 R_X86_64_JUMP_SLO 0000000000201210 puts@GLIBC_2.2.5 + 0\n000000202028  000200000007 R_X86_64_JUMP_SLO 00000000002011f0 printf@GLIBC_2.2.5 + 0\n</pre>\n\n<p>\nNotice how both the (PLT)GOT entry offset (first column) and the PLT stub offset (4th column) is different between the two binaries built from the same source code. Both binaries have equivalent I/O behaviour, but this internal detail is different, thanks to the custom compiler toolchain.\n</p>\n\n<p>\nThe benefits of this technique are that\n<ol>\n<li>it makes GOT overwrite exploits less portable, and</li>\n<li>currently pwntools incorrectly determines the PLT stub offsets for these binaries, so more care and manual labour are necessary for a successful exploit.</li>\n</ol>\n<small>(In fact, it turns out that correctly determining which PLT stub belongs to which library function is a difficult problem. libbfd only manages by assuming the code for a PLT stub, and extracting the <code>.rela.plt</code> entry offset from a known location inside the stub. This means that fixing this in pwntools is not straightforward. Also worth mentioning is that the DynELF module of pwntools also fails for executables produced by this custom toolchain, simply because the ELF base address is different from that in the default GNU linker scripts. My pull request fixing this is already on the way, however.)</small>\n</p>\n\n<p>\nI am aware of one minor downside to using this technique. The challenge author can no longer guarantee that GOT or PLT offsets do not contain any NUL bytes. During my testing, I could always overcome this by smuggling in the NUL byte, overwriting a different GOT entry, or jumping straight onto the lazy loader stub instead of the beginning of the PLT stub, but there is no guarantee that either of these will work for all challenges,\n so challenge authors need to keep this in mind.\n</p>",
     name: "gotplt-html"
    },
    {
     type: "comment",
     name: "gotplt-limitations",
     title: "Can you think of any limitations or downsides of this technique that I have failed to notice?"
    },
    {
     type: "radiogroup",
     name: "gotplt-applicable",
     title: "Do you think you could use this technique for binary exploitation or reverse engineering challenges you develop?",
     choices: [
      {
       value: "almost-always",
       text: "Almost always"
      },
      {
       value: "sometimes",
       text: "Sometimes"
      },
      {
       value: "almost-never",
       text: "Almost never"
      }
     ]
    },
    {
     type: "checkbox",
     name: "gotplt-why-not",
     title: "Imagine that a system like this was freely available under a permissive open source license. Please tick any of the concerns below that might keep you from using it for challenges where it is applicable.",
     hasOther: true,
     choices: [
      {
       value: "complex",
       text: "It would make challenge development overly complex"
      },
      {
       value: "time-consuming",
       text: "It would be unreasonably time-consuming"
      },
      {
       value: "pointless",
       text: "It would be pointless"
      },
      {
       value: "resource-intensive",
       text: "It would be too resource-intensive"
      },
      {
       value: "quality",
       text: "It would harm the quality of the challenge"
      }
     ],
     otherText: "Other (please elaborate)"
    },
    {
     type: "comment",
     name: "gotplt-feedback",
     title: "Do you have any other relevant thoughts, concerns, or questions?"
    }
   ],
   title: "Variation in linking",
   visible: false,
   visibleIf: "({has-experience-solving}='yes' or {has-experience-authoring}='yes')"
  },
  {
   name: "codegen",
   questions: [
    {
     type: "html",
        html: "<p>\nAnother group of techniques focuses on the code generation phase of the compilation process. By making a small number of focused changes to LLVM, a number of variations can be introduced into the output. Using an example similar to the previous one, we can once again demonstrate the effect. The following <code>c_flags</code> will be used.\n</p>\n\n<pre>\n# test.chall\n# ...\nc_flags :randomize_branches =&gt; :aggressive, :randomize_regs =&gt; true, :randomize_scheduling =&gt; true\nc_compiled 'test' =&gt; 'test.c'\n# ...\n</pre>\n\n<p>\nThis time it is also worth choosing a slightly more complicated test program, like the following one.\n</p>\n\n<pre>\n#include &lt;stdio.h&gt;\n\nint main(int argc, char **argv) {\n  int f = ((argc &lt;&lt; 2) & 0xF0F0F0F0) | ((argc * 3) & 0x0F0F0F0F);\n  printf(\"You gave me %d arguments, and f(%d)=%d.\\n\", argc, argc, f);\n  if (f &lt;= 5)\n    return 0;\n  else\n    return 1;\n}\n</pre>\n\n<p>\nCompiling this code twice, and disassembling the resulting <code>main</code> functions may result in something like the diff below.\n</p>\n\n<pre>\ngabor@part2-project:/tmp/demo$ diff -ay -W 140 &lt;(gdb -batch -ex 'disass main' test1) &lt;(gdb -batch -ex 'disass main' test2)\nDump of assembler code for function main:\t\t\t\tDump of assembler code for function main:\n   0x0000000000201100 &lt;+0&gt;:\tpush   rbp\t\t\t\t   0x0000000000201100 &lt;+0&gt;:\tpush   rbp\n   0x0000000000201101 &lt;+1&gt;:\tmov    rbp,rsp\t\t\t\t   0x0000000000201101 &lt;+1&gt;:\tmov    rbp,rsp\n   0x0000000000201104 &lt;+4&gt;:\tsub    rsp,0x20\t\t\t\t   0x0000000000201104 &lt;+4&gt;:\tsub    rsp,0x20\n   0x0000000000201108 &lt;+8&gt;:\tmovabs rax,0x2002b0\t\t     |\t   0x0000000000201108 &lt;+8&gt;:\tmov    DWORD PTR [rbp-0x8],0x0\n   0x0000000000201112 &lt;+18&gt;:\tmov    DWORD PTR [rbp-0x4],edi\t     |\t   0x000000000020110f &lt;+15&gt;:\tmov    QWORD PTR [rbp-0x18],rsi\n   0x0000000000201115 &lt;+21&gt;:\tmov    edi,DWORD PTR [rbp-0x4]\t     |\t   0x0000000000201113 &lt;+19&gt;:\tmov    DWORD PTR [rbp-0x4],edi\n   0x0000000000201118 &lt;+24&gt;:\tshl    edi,0x2\t\t\t     |\t   0x0000000000201116 &lt;+22&gt;:\timul   edi,DWORD PTR [rbp-0x4],0x3\n   0x000000000020111b &lt;+27&gt;:\tand    edi,0xf0f0f0f0\t\t     |\t   0x000000000020111a &lt;+26&gt;:\tand    edi,0xf0f0f0f\n   0x0000000000201121 &lt;+33&gt;:\tmov    QWORD PTR [rbp-0x18],rsi\t     |\t   0x0000000000201120 &lt;+32&gt;:\tmov    esi,DWORD PTR [rbp-0x4]\n   0x0000000000201125 &lt;+37&gt;:\tmov    edx,DWORD PTR [rbp-0x4]\t     |\t   0x0000000000201123 &lt;+35&gt;:\tshl    esi,0x2\n   0x0000000000201128 &lt;+40&gt;:\timul   ecx,DWORD PTR [rbp-0x4],0x3   |\t   0x0000000000201126 &lt;+38&gt;:\tand    esi,0xf0f0f0f0\n   0x000000000020112c &lt;+44&gt;:\tmov    esi,DWORD PTR [rbp-0x4]\t     |\t   0x000000000020112c &lt;+44&gt;:\tor     edi,esi\n   0x000000000020112f &lt;+47&gt;:\tmov    DWORD PTR [rbp-0x8],0x0\t     |\t   0x000000000020112e &lt;+46&gt;:\tmov    DWORD PTR [rbp-0xc],edi\n   0x0000000000201136 &lt;+54&gt;:\tand    ecx,0xf0f0f0f\t\t     |\t   0x0000000000201131 &lt;+49&gt;:\tmovabs rdi,0x2002b0\n   0x000000000020113c &lt;+60&gt;:\tor     ecx,edi\t\t\t     |\t   0x000000000020113b &lt;+59&gt;:\tmov    esi,DWORD PTR [rbp-0x4]\n   0x000000000020113e &lt;+62&gt;:\tmov    DWORD PTR [rbp-0xc],ecx\t     |\t   0x000000000020113e &lt;+62&gt;:\tmov    edx,DWORD PTR [rbp-0x4]\n   0x0000000000201141 &lt;+65&gt;:\tmov    ecx,DWORD PTR [rbp-0xc]\t\t   0x0000000000201141 &lt;+65&gt;:\tmov    ecx,DWORD PTR [rbp-0xc]\n   0x0000000000201144 &lt;+68&gt;:\tmov    rdi,rax\t\t\t     |\t   0x0000000000201144 &lt;+68&gt;:\tmov    al,0x0\n   0x0000000000201147 &lt;+71&gt;:\tmov    al,0x0\t\t\t     |\t   0x0000000000201146 &lt;+70&gt;:\tcall   0x201230 &lt;printf@plt&gt;\n   0x0000000000201149 &lt;+73&gt;:\tcall   0x201230 &lt;printf@plt&gt;\t     |\t   0x000000000020114b &lt;+75&gt;:\tcmp    DWORD PTR [rbp-0xc],0x5\n   0x000000000020114e &lt;+78&gt;:\tcmp    DWORD PTR [rbp-0xc],0x5\t     |\t   0x000000000020114f &lt;+79&gt;:\tjg     0x20115a &lt;main+90&gt;\n   0x0000000000201152 &lt;+82&gt;:\tjle    0x20115d &lt;main+93&gt;\t     |\t   0x0000000000201151 &lt;+81&gt;:\tmov    DWORD PTR [rbp-0x8],0x0\n   0x0000000000201154 &lt;+84&gt;:\tmov    DWORD PTR [rbp-0x8],0x1\t     |\t   0x0000000000201158 &lt;+88&gt;:\tjmp    0x201161 &lt;main+97&gt;\n   0x000000000020115b &lt;+91&gt;:\tjmp    0x201164 &lt;main+100&gt;\t     |\t   0x000000000020115a &lt;+90&gt;:\tmov    DWORD PTR [rbp-0x8],0x1\n   0x000000000020115d &lt;+93&gt;:\tmov    DWORD PTR [rbp-0x8],0x0\t     |\t   0x0000000000201161 &lt;+97&gt;:\tmov    eax,DWORD PTR [rbp-0x8]\n   0x0000000000201164 &lt;+100&gt;:\tmov    eax,DWORD PTR [rbp-0x8]\t     |\t   0x0000000000201164 &lt;+100&gt;:\tadd    rsp,0x20\n   0x0000000000201167 &lt;+103&gt;:\tadd    rsp,0x20\t\t\t     |\t   0x0000000000201168 &lt;+104&gt;:\tpop    rbp\n   0x000000000020116b &lt;+107&gt;:\tpop    rbp\t\t\t     |\t   0x0000000000201169 &lt;+105&gt;:\tret    \n   0x000000000020116c &lt;+108&gt;:\tret    \t\t\t\t     &lt;\nEnd of assembler dump.\t\t\t\t\t\t\tEnd of assembler dump.\n</pre>\n\n<p>\nThere are 3 classes of differences in the two functions, so I will point out a representative example of each.\n</p>\n\n<ol>\n<li>\nThe most obvious difference is in the order of instructions. Moderately careful observation will reveal that most instructions in the two excerpts are the same, but their ordering is considerably different (e.g. look at the instructions loading the format string, at offsets +8 and +49, respectively). This is because the freedom in the instruction scheduling phase is used to introduce variation: instructions with no data dependency between them can be reordered. This is controlled by the <code>randomize_scheduling</code> flag above. Instructions are only reordered within scheduling blocks, which do not cross basic block boundaries, so overall code layout is conserved.\n</li>\n<li>\nNotice how the conditional jump in the first version got compiled to roughly what would be reasonable to expect based on the C code,\n but in the second case instead the inverse predicate is used (<code>jg</code>\n instead of <code>jle</code>). This is a result of enabling the <code>randomize_branches</code> compilation flag. This technique influences how compare-and-branch situations like this are compiled. For a particular conditional branch, swapping the arguments of the compare instruction, and swapping the jump/fall-through edges of the branch instruction yields four different cases. However, in practice, not all four choices are equally convenient (mainly because x86_64 <code>cmp</code> instructions do not support immediate expressions as their first operand, and fall-through opportunities may be lost by swapping the outgoing edges of branch instructions). Therefore the aggressivity of the randomisation can be controlled by specifying values other than <code>true</code> or <code>:yes</code> for this option. Supported levels are: <code>none</code>, <code>conservative</code>, <code>reasonable</code> (default), <code>aggressive</code>.\n</li>\n<li>\nObserve how the corresponding <code>or</code> instructions in the two test cases (at +60 and +44 respectively) reference completely different registers. In the first example the left and right halves of the expression for <code>f</code> are in <code>ecx</code> and <code>edi</code>, respectively, in the second example they are in <code>edi</code> and <code>esi</code>.  Once again this is an example of exploiting the remarkable freedom the compiler has. At that point in the program, multiple registers were available for use, so instead of picking the first one (the best according to some heuristic), a random choice was made. This is enabled by the <code>randomize_regs</code> setting in the example above.\n</li>\n</ol>\n\n<p>\nThe benefit of using these techniques should be self-explanatory, having seen this example. The code looks rather different, despite still doing the same thing. It is especially interesting to see how different the bodies of large functions with many conditional statements (or switches) look.\n</p>\n\n<p>\nHowever, once again, the benefits come at a cost. I am not aware of any major problems, but there are small things that may go wrong. The most important one is that if code size is small, the range of available ROP gadgets may vary wildly. This rarely is a problem that would make the challenge instance insoluble, but the difficulty of a challenge might depend on how easy it is to construct a useful ROP chain, so challenge authors need to keep this in mind. Fortunately, the issue can be treated well by adding some bulk code.\n</p>\n<p>\nThe other concerns are performance-related and therefore not critical to CTFs, but I mention them for completeness. The decisions any serious compiler makes in cases like those detailed above are usually a lot better justifiable than 'this is what the random generator picked'. Interfering with these heuristics will necessarily have a performance impact. My impression is that this impact is orders of magnitude smaller than what would make a difference in a CTF setting.\n</p>\n<p>\nMore specifically, the reordering is not expected to have any significant effect on performance, as modern CPUs will quite probably reorder the affected instructions internally anyway. The other two techniques will often increase register pressure, which may lead to spilling. Changing branch layouts may also necessitate the addition of further (unconditional) jumps, which will increase code size, and decrease performance. However, once again, my view is that this is an entirely reasonable price to pay in a CTF.\n</p>",
     name: "codegen-html"
    },
    {
     type: "comment",
     name: "codegen-limitations",
     title: "Can you think of any limitations or downsides of this technique that I have failed to notice?"
    },
    {
     type: "radiogroup",
     name: "codegen-applicable",
     title: "Do you think you could use this technique for binary exploitation or reverse engineering challenges you develop?",
     choices: [
      {
       value: "almost-always",
       text: "Almost always"
      },
      {
       value: "sometimes",
       text: "Sometimes"
      },
      {
       value: "almost-never",
       text: "Almost never"
      }
     ]
    },
    {
     type: "checkbox",
     name: "codegen-why-not",
     title: "Imagine that a system like this was freely available under a permissive open source license. Please tick any of the concerns below that might keep you from using it for challenges where it is applicable.",
     hasOther: true,
     choices: [
      {
       value: "complex",
       text: "It would make challenge development overly complex"
      },
      {
       value: "time-consuming",
       text: "It would be unreasonably time-consuming"
      },
      {
       value: "pointless",
       text: "It would be pointless"
      },
      {
       value: "resource-intensive",
       text: "It would be too resource-intensive"
      },
      {
       value: "quality",
       text: "It would harm the quality of the challenge"
      }
     ],
     otherText: "Other (please elaborate)"
    },
    {
     type: "comment",
     name: "codegen-feedback",
     title: "Do you have any other relevant thoughts, concerns, or questions?"
    }
   ],
   title: "Variation in code generation",
   visible: false,
   visibleIf: "({has-experience-solving}='yes' or {has-experience-authoring}='yes')"
  },
  {
   name: "code-layout",
   questions: [
    {
     type: "html",
     html: "<p>\nThe last class of techniques I will discuss is of those that try to perturb the placement of symbols in the final binary. Since this is a fairly simple concept, I will not provide an example, just describe the specifics briefly. Three separate techniques of this class are being used.\n</p>\n\n<ol>\n<li>The order in which function bodies appear in the intermediate object files is randomised. This is enabled by the <code>reorder_functions</code>\n option.</li>\n<li>The same is done to global variables in the data section. It is worth pointing out that this applies to more than just the things explicitly defined as global variables. For example, one of the most useful outcomes is that the positions of vtables for C++ classes also change. The respective option is <code>reorder_globals</code>.</li>\n<li>The somewhat awkwardly named <code>randomize_function_spacing</code> option instructs the compiler to insert a random (within user-specified limits) number of junk bytes after each function. This is done in an attempt to further mix up the placement of functions in the executable, and is particularly useful when the effect of the previously described code generation techniques is not enough, or they are not applicable.</li>\n</ol>\n\n<p>\nIt is easy to underestimate the usefulness of these sources of variation, since they are as simple as it gets. However, they are actually quite effective at making exploits less portable. Moving code around means that jump targets, ROP gadgets, and breakpoints all move around, and in case of a stripped binary, identifying functions alone might pose difficulty. Overwriting global data items (function pointers, vtables) are often the means of seizing control of the instruction pointer, or achieving other desirable outcomes. Therefore moving them around is indeed meaningful.\n</p>\n\n<p>\nThe most important drawback once again concerns NUL bytes. Similarly to what happened with randomising the PLT or (PLT)GOT entry order, NUL bytes may suddenly appear in addresses, which may in some cases cause serious complications. Once again this is something that challenge authors should think of when designing their challenge. In cases where for some reason the order of global symbols has particular significance, these techniques obviously cannot be applied, but I believe these are fairly uncommon. There probably is an adverse effect on cache performance as well, since accesses to code or data items defined in close proximity of each other in the source code are likely to be somewhat correlated, but I struggle to imagine a CTF challenge where this might matter.\n</p>",
     name: "code-layout-html"
    },
    {
     type: "comment",
     name: "code-layout-limitations",
     title: "Can you think of any limitations or downsides of this technique that I have failed to notice?"
    },
    {
     type: "radiogroup",
     name: "code-layout-applicable",
     title: "Do you think you could use this technique for binary exploitation or reverse engineering challenges you develop?",
     choices: [
      {
       value: "almost-always",
       text: "Almost always"
      },
      {
       value: "sometimes",
       text: "Sometimes"
      },
      {
       value: "almost-never",
       text: "Almost never"
      }
     ]
    },
    {
     type: "checkbox",
     name: "code-layout-why-not",
     title: "Imagine that a system like this was freely available under a permissive open source license. Please tick any of the concerns below that might keep you from using it for challenges where it is applicable.",
     hasOther: true,
     choices: [
      {
       value: "complex",
       text: "It would make challenge development overly complex"
      },
      {
       value: "time-consuming",
       text: "It would be unreasonably time-consuming"
      },
      {
       value: "pointless",
       text: "It would be pointless"
      },
      {
       value: "resource-intensive",
       text: "It would be too resource-intensive"
      },
      {
       value: "quality",
       text: "It would harm the quality of the challenge"
      }
     ],
     otherText: "Other (please elaborate)"
    },
    {
     type: "comment",
     name: "code-layout-feedback",
     title: "Do you have any other relevant thoughts, concerns, or questions?"
    }
   ],
   title: "Variation in code layout",
   visible: false,
   visibleIf: "({has-experience-solving}='yes' or {has-experience-authoring}='yes')"
  },
  {
   name: "fine",
   questions: [
    {
     type: "html",
     html: "This is the end of the questionnaire. Thank you for making it this far! If you would like you can still go back and check/change your answers. When you are done, hit 'Complete' below.",
     name: "fine-html"
    }
   ],
   title: "Fine - The end"
  }
 ]
}

Survey.Survey.cssType = "bootstrap";

var survey = new Survey.Survey(surveyJSON, "surveyContainer");

var saved = window.localStorage.getItem(uuid);
if (saved != null)
    survey.data = JSON.parse(saved);

survey.completedHtml = "\
<h3>Thank you for completing the survey!</h3>\
<div id=\"saving\">\
<h4>Your answers are being recorded.</h4>\
</div>\
<div id=\"success\" style=\"display: none;\">\
<h4>Your answers have been saved.</h4>\
</div>\
<div id=\"error\" style=\"display: none;\">\
<h4>Unfortunately, your answers could not be saved.</h4>\
<p>Don't worry, they're not lost! They have been saved in your browser, so when you visit this survey again, your past answers will be here. Please wait a little bit, refresh this page, and try to save the survey again. If it still does not work, please contact me on the email address below.</p>\
</div>\
<p>If you happened to be interested in these techniques, please visit <a href=\"https://gs509.user.srcf.net/blinker/\">the website</a>, where you will be able to download a copy to experiment with.</p>\
";

survey.onValueChanged.add(function (survey) {
    window.localStorage.setItem(uuid, JSON.stringify(survey.data));
});

survey.onComplete.add(function(survey) {
    var success = function() {
        $('#saving').css('display', 'none');
        $('#success').css('display', 'block');
        window.localStorage.removeItem(uuid);
    };

    var error = function() {
        $('#saving').css('display', 'none');
        $('#error').css('display', 'block');
    };

    $.ajax(window.location.href,
           { method: "POST",
             data: {
                 answers: JSON.stringify(survey.data),
                 uuid: uuid
             },
             success: success,
             error: error });
});
