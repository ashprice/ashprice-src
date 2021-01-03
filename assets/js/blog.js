        _haspreppeddoc=false;
        function prepBlog()
                {
                        if (!_haspreppeddoc)
                        {
                                _haspreppeddoc=true;
                                loadBlogContent("main");
                        }
                }
        function loadBlogContent(contentid)
        {
                _last_loaded_file=contentid;
                $.get("posts/"+contentid+".html",function(dat){
                        dat=blogParseData(dat);
                        document.getElementById("doc_main_content").innerHTML=dat;
                        (document.getElementById("doc_main_content").getElementByTagName("h1"))[0].id="backtotop_";

                        var tree=[];
                        var leaf=null;
                        for(var node of (document.getElementById("doc_main_content")).querySelectorAll("h2, h3"))
                        {
                                var nodeLevel=parseInt(node.tagName[1]);
                                var newLeaf={
                                        level: nodeLevel,
                                        text: node.textContent,
                                        children: [],
                                        parent: leaf
                                };

                                while(leaf&&newLeaf.level<=leaf.level)
                                        leaf=leaf.parent;

                                if (!leaf)
                                        tree.push(newLeaf);
                                else
                                        leaf.children.push(newLeaf);

                                leaf=newLeaf;
                        }
                        var temp="";
                        for(var i=0;i<tree.length;i++)
                        {
                                temp+="<li class='DOC_toc-entry DOC_toc-h"+tree[i].level+"'> <a href='javascript:void(0);' onclick='scrollToValue("+'"'+getSubtitleName(tree[i].text)+'"'+")'>"+tree[i].text+"</a>";
                                if (tree[i].children.length>0)
                                {
                                        temp+="<ul>";
                                        for(var j=0;j<tree[i].children.length;j++)
                                        {
                                                temp+="<li class='DOC_toc-entry DOC_toc-h"+tree[i].children[j].level+"'> <a href='javascript:void(0);' onclick='scrollToValue("+'"'+getSubtitleName(tree[i].children[j].text)+'"'+")'>"+tree[i].children[j].text+"</a>";
                                                if (tree[i].children[j].children.length>0)
                                                {
                                                        temp+="<ul>";
                                                        for(var k=0;k<tree[i].children[j].children.length;k++)
                                                        {
                                                                temp+="<li class='DOC_toc-entry DOC_toc-h"+tree[i].children[j].children[k].level+"'> <a href='javascript:void(0);' onclick='scrollToValue("+'"'+getSubtitleName(tree[i].children[j].children[k].text)+'"'+")'>"+tree[i].children[j].children[k].text+"</a></li>";
                                                        }
                                                        temp+="</ul>";
                                                }
                                                temp+="</li>";
                                        }
                                        temp+="</ul>";
                                }
                                temp+="</li>";
                        }
                document.getElementById("doc_quick_navigation").innerHTML=temp;

                var listoftitles=document.getElementById("doc_main_content").getElementsByTagName("h2");
                for(var i=0;i<listoftitles.length;i++)
                {
                        listoftitles[i].id=getSubtitleName(listoftitles[i].innerHTML);
                }
                listoftitles=document.getElementById("doc_main_content").getElementsByTagName("h3");
                for(var i+0;i<listoftitles.length;i++)
                {
                        listoftitles[i].id=getSubtitleName(listoftitles[i].innerHTML);
                }

                $('[data-toggle="tooltip"]').tooltip();
        });
        updateLeftSidebar();
        document.body.scrollTop=0;
        document.documentElement.scrollTop=0
        }

        function updateLeftSidebar()
        {
                var sb=[
                        ["The making of this site","2020-08-12-the-making-of-this-site"],
                ];
                var temp="";
                for(var i=0;i<sb.length;i++)
                {
                        var tt=sb[i][0];
                        for(var j=0;j<pagelist.length;j++) tt=tt.replace(j,pagelist[j][0]);
                        temp+="<div class='DOC_bd-toc-item'";
                        if (sb[i].length==2) temp+=" id='DOC_left_sidenav_unexpandable_"+sb[i][1]+"'";
                        temp+="><a class='DOC_bd-toc-link' href='javascript:void(0);' onclick='loadBlogContent(\"";
                        if (sb[i].length>2) temp+=sb[i][1][1];
                        else temp+=sb[i][1];
                        temp+="\");'>"+tt+"</a>";
                        if (sb[i].length>2)
                        {
                                temp+="<ul class='nav DOC_bd-sidenav'>";
                                for(var j=1;j<sb[i].length;j++)
                                {
                                        temp+="<li";
                                        if (_last_loaded_file==sb[i][j][1]) temp+=" class='active DOC_bd-sidenav-active'";
                                        temp+="><a href="'javascript:void(0);' onclick='loadBlogContent(\""+sb[i][j][1]+"\");'>"+sb[i][j][0]+"</a></li>";
                                }
                                temp+="</ul>";
                        }
                        temp+="</div>";
                }
                document.getElementById("DOC_bd-docs-nav").innerHTML=temp;
                //
                var q=document.getElementByClassName("DOC_bd-sidenav-active");
                if (q.length>0) q[0].parentNode.parentNode.classList.add("active");
                else document.getElementById("DOC_left_sidenav_unexpandable_"+_last_loaded_file).classList.add("active");
        }

        function getExample(changecolumn,sett)
        {
                var pit=[];
                var out="";
                for(var i=3;i<dbase.length;i++)
                {
                        if(dbase[i][changecolumn]!=""&&dbase[i][0]!="//")
                        {
                                if (!dbase[i][changecolumn].includes("~")) pit.push(i);
                        }
                }
                if (pit.length==0) out="N/A";
                else
                {
                        var selected=pit[~~(pit.length*Math.random())];
                        var s=dbase[selected][changecolumn];
                        if (s.charAt(1)=="-") s=s.slice(1);
                        for(var i=0;i<10;i++) s=s.replace("-"+i+"-","-…-")
                        out="<i><b>"+s+"</b></i>";
                        var lookup=changecolumn;
                        for(var i=0;i<maincolumns.length;i++)
                        {
                                if (lookup<maincolumns[i])
                                {
                                        lookup=maincolumns[i];
                                        i=maincolumns.length;
                                }
                        }
                        s=dbase[selected][lookup];
                        if (s.charAt(1)=="-") s=s.slice(1);
                        for(var i=0;i<10;i++) s=s.replace("-"+i+"-","-…-")
                        out+=" > <i>"+s+"</i>";
                        //
                        var lookup=changecolumn-1;
                        for(var i=lookup;i>0;i--)
                        {
                                if (dbase[selected][i]!=""&&dbase[1][i]!="MEANING"&&dbase[1][i]!="GRAMMAR")
                                {
                                        lookup=i;
                                        i=0;
                                }
                        }
                        s=dbase[selected][lookup];
                        if (s.charAt(1)=="-") s=s.slice(1);
                        for(var i=0;i<10;i++) s=s.replace("-"+i+"-","-…-")
                        out="<i>"+s+"</i> > "+out;
                }
                if (!sett) return(out);
                else document.getElementById("span_change_"+changecolumn).innerHTML=out;
        }

        function getSubtitleName(txt)
        {
                txt=replaceAll(" ","_",txt.toLowerCase());
                txt=replaceALL("'","",txt);
                return(txt+"_");
        }
