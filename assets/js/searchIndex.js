
var camelCaseTokenizer = function (builder) {

  var pipelineFunction = function (token) {
    var previous = '';
    // split camelCaseString to on each word and combined words
    // e.g. camelCaseTokenizer -> ['camel', 'case', 'camelcase', 'tokenizer', 'camelcasetokenizer']
    var tokenStrings = token.toString().trim().split(/[\s\-]+|(?=[A-Z])/).reduce(function(acc, cur) {
      var current = cur.toLowerCase();
      if (acc.length === 0) {
        previous = current;
        return acc.concat(current);
      }
      previous = previous.concat(current);
      return acc.concat([current, previous]);
    }, []);

    // return token for each string
    // will copy any metadata on input token
    return tokenStrings.map(function(tokenString) {
      return token.clone(function(str) {
        return tokenString;
      })
    });
  }

  lunr.Pipeline.registerFunction(pipelineFunction, 'camelCaseTokenizer')

  builder.pipeline.before(lunr.stemmer, pipelineFunction)
}
var searchModule = function() {
    var documents = [];
    var idMap = [];
    function a(a,b) { 
        documents.push(a);
        idMap.push(b); 
    }

    a(
        {
            id:0,
            title:"CodeFixResources",
            content:"CodeFixResources",
            description:'',
            tags:''
        },
        {
            url:'/Cake.Addin.Analyzer/api/Cake.Addin.Analyzer.CodeFixes/CodeFixResources',
            title:"CodeFixResources",
            description:""
        }
    );
    a(
        {
            id:1,
            title:"Identifiers",
            content:"Identifiers",
            description:'',
            tags:''
        },
        {
            url:'/Cake.Addin.Analyzer/api/Cake.Addin.Analyzer.Constants/Identifiers',
            title:"Identifiers",
            description:""
        }
    );
    a(
        {
            id:2,
            title:"BaseRule",
            content:"BaseRule",
            description:'',
            tags:''
        },
        {
            url:'/Cake.Addin.Analyzer/api/Cake.Addin.Analyzer.Rules/BaseRule',
            title:"BaseRule",
            description:""
        }
    );
    a(
        {
            id:3,
            title:"Categories",
            content:"Categories",
            description:'',
            tags:''
        },
        {
            url:'/Cake.Addin.Analyzer/api/Cake.Addin.Analyzer.Constants/Categories',
            title:"Categories",
            description:""
        }
    );
    a(
        {
            id:4,
            title:"AliasClassCategoryRule",
            content:"AliasClassCategoryRule",
            description:'',
            tags:''
        },
        {
            url:'/Cake.Addin.Analyzer/api/Cake.Addin.Analyzer.Rules/AliasClassCategoryRule',
            title:"AliasClassCategoryRule",
            description:""
        }
    );
    a(
        {
            id:5,
            title:"BaseCodeFixProvider",
            content:"BaseCodeFixProvider",
            description:'',
            tags:''
        },
        {
            url:'/Cake.Addin.Analyzer/api/Cake.Addin.Analyzer.CodeFixes/BaseCodeFixProvider',
            title:"BaseCodeFixProvider",
            description:""
        }
    );
    a(
        {
            id:6,
            title:"AliasClassCategoryCodeFixProvider",
            content:"AliasClassCategoryCodeFixProvider",
            description:'',
            tags:''
        },
        {
            url:'/Cake.Addin.Analyzer/api/Cake.Addin.Analyzer.CodeFixes/AliasClassCategoryCodeFixProvider',
            title:"AliasClassCategoryCodeFixProvider",
            description:""
        }
    );
    a(
        {
            id:7,
            title:"AliasMethodMarkedCodeFixProvider",
            content:"AliasMethodMarkedCodeFixProvider",
            description:'',
            tags:''
        },
        {
            url:'/Cake.Addin.Analyzer/api/Cake.Addin.Analyzer.CodeFixes/AliasMethodMarkedCodeFixProvider',
            title:"AliasMethodMarkedCodeFixProvider",
            description:""
        }
    );
    a(
        {
            id:8,
            title:"AliasMethodMarkedRule",
            content:"AliasMethodMarkedRule",
            description:'',
            tags:''
        },
        {
            url:'/Cake.Addin.Analyzer/api/Cake.Addin.Analyzer.Rules/AliasMethodMarkedRule',
            title:"AliasMethodMarkedRule",
            description:""
        }
    );
    var idx = lunr(function() {
        this.field('title');
        this.field('content');
        this.field('description');
        this.field('tags');
        this.ref('id');
        this.use(camelCaseTokenizer);

        this.pipeline.remove(lunr.stopWordFilter);
        this.pipeline.remove(lunr.stemmer);
        documents.forEach(function (doc) { this.add(doc) }, this)
    });

    return {
        search: function(q) {
            return idx.search(q).map(function(i) {
                return idMap[i.ref];
            });
        }
    };
}();
