# -*- coding: utf-8 -*-
"""
Workaround to make Jmol work in the Sage Notebook live help.

Related issue: https://github.com/sagemath/sagenb/issues/179

Based on code from: 
- Sage Math version 5.11rc1
- Sage Notebook version 0.10.4

Wich are the current running versions at www.sagenb.org up to May 29th, 2014.

Particularly:

- sage.plot.plot3d.base.Graphics3d.show() method.
  https://github.com/sagemath/sage/blob/5.11.rc1/src/sage/plot/plot3d/base.pyx#L970
- sagenb.notebook.cell.Cell.files_html() method.
  https://github.com/sagemath/sagenb/blob/0.10.4/sagenb/notebook/cell.py#L2294
  
This code was intended to work from any normal worksheet at www.sagenb.org
and its primary goal: inside the live help (aka the docbrowser).

Example:

    sage: load('https://raw.githubusercontent.com/aghu/'
    ....:      'contributions/master/jmol_manual_html_render.sage')
    sage: g(x,y) = sin(x^2+y^2)
    sage: P = plot3d(g,(x,-5,5),(y,-5,5))
    sage: jmol_manual_html_render(P)

From www.sagenb.org, login, go to: 
* -> Help -> Thematic Tutorials 
* -> Tutorial Symbolics and Plotting -> Basic 3D plotting 
* Change cell contents to look like the example.
* Evaluate.

You might also copy-paste the entire code directly into the cell
to inspect/debug it.
"""

# **************************************************************************
# Copyright (C) 2014 Another GitHub User, https://github.com/aghu
#
# Distributed under the terms of the GNU General Public License (GPL)
# either version 3 of the License, or (at your option) any later version.
# http://www.gnu.org/licenses/
# **************************************************************************



# Need to know from what URL, the local files at DATA can 
# be accessed at the browser (or server).
# The regexp is intended to capture the two parent directories
# of DATA. I assume that is the directory of the 'user'.
# DATA is assumed to be like:
# '/sagenb/servers/sage_notebook-sagenb.sagenb/home/' +
# 'name_of_user/31/data/'
#
# Or like:
# '/sagenb/servers/sage_notebook-sagenb.sagenb/home/' +
# '__store__/a/a1/a1b/a1b1/name_of_user/31/data/'
import re
data_url = re.match(r"^.*?/([^/]+?/[^/]+?/data/$)",DATA).group(int(1))
data_url = os.path.join('/home',data_url)
DATA_URL = data_url

def jmol_manual_html_render(g3d,purge_data=True):
    # We're working on DATA dir to avoid automatic cell 
    # files detection of '.jmol' and '.jmol.zip'.
    # So we might need to keep DATA clean.
    if purge_data:
        for ff in os.listdir(DATA):
            pp = DATA + ff
            if os.path.isfile(pp):
                os.remove(pp)

    import sagenb
    cell_id = sagenb.notebook.interact.SAGE_CELL_ID
    
    # Mimic sage.plot.plot3d.base.Graphics3d.show()
    # ---------------------------------------------
    
    from sage.plot.plot import EMBEDDED_MODE
    # print "EMBEDDED_MODE =",EMBEDDED_MODE
    
    import time   
    
    opts = g3d._process_viewing_options({})
    g_J  = g3d._prepare_for_jmol(
                opts['frame'], opts['axes'],
                opts['frame_aspect_ratio'],
                opts['aspect_ratio'],opts['zoom'])
    
    filename  = sage.misc.temporary_file.graphics_filename()[:-4]
    base, ext = os.path.splitext(filename)
    
    fg       = opts['figsize'][0]
    filename = '%s-size%s%s'%(base, fg*100, ext)
    
    ext          = "jmol"
    archive_name = "%s-%s.%s.zip" % (filename, randint(0, 1 << 30), ext)
    # print "archive_name =",DATA+archive_name
    # print "  real       =",os.path.realpath(DATA+archive_name)
    
    g_J.export_jmol(DATA+archive_name, force_reload=EMBEDDED_MODE, zoom=100)
    
    png_path = DATA + '.jmol_images'
    sage.misc.misc.sage_makedirs(png_path)
    
    # path = "cells/%s/%s" %(cell_id, archive_name)
    path = DATA_URL + archive_name
    
    # print "path   =", path
    # print "  real =",os.path.realpath(path)
    script_name = filename + '.' + ext
    
    with open(DATA+script_name, 'w') as f:
        f.write('set defaultdirectory "%s"\n' % path)
        f.write('script SCRIPT\n')

    # print "script_name =", DATA+script_name
    # print "  real   =",os.path.realpath(DATA+script_name)

    
    # Below for debugging dir contents.
    
    # D = os.listdir(os.path.realpath(os.path.curdir))
    # D.sort()
    # print "curdir =",os.path.realpath(os.path.curdir)
    # print "  files:",D
    # D = os.listdir(os.path.realpath(DATA))
    # D.sort()
    # print "DATA =",os.path.realpath(DATA)
    # print "  files:",D
    
    
    # Links for debugging the generated files, from the browser
    # ---------------------------------------------------------
    
    import zipfile
    z = zipfile.ZipFile(DATA + archive_name)
    z.namelist()
    html_for_links =''
    for ff in z.namelist():
        z.extract(ff,DATA)
        tt = ff +'.txt'
        os.rename(DATA+ff,DATA+tt)
        html_for_links += ('<a href="%(url)s?%(time)d" '
                              'target="_blank">%(file)s</a>' 
                           % dict(url=DATA_URL + tt,file=tt,
                                  time=time.time()))
        html_for_links += '<br>\n'
        
    script_txt = script_name + '.txt'
    os.link( DATA + script_name, DATA + script_txt)
    html_for_links += ('<a href="%(url)s?%(time)d" '
                          'target="_blank">%(file)s</a>' 
                       % dict(url=DATA_URL + script_txt,
                              file=script_txt,
                              time=time.time()))
    
    # Mimic sagenb.notebook.cell.Cell.files_html()
    # --------------------------------------------
    
    F = script_name
    url = os.path.join(DATA_URL, F)
    size = 500 
    
    script = (('<div id = "jmol_manual_render_%(cell_id)s">\n'
               '<div id = "jmol_static%(cell_id)s" style="display: none;">\n'
               '<script>\n'
                   'setTimeout(function() {\n'
                        'jmol_applet(%(size)s,"%(url)s?%(time)d",\n'
                                     '%(cell_id)s);},\n' 
                        '100);\n'
               '</script></div></div>\n'
               ) % dict(cell_id=cell_id, size=size, url=url, time=time.time()))
    
    # print script
    
    html("<pre>" + html_for_links + "</pre>" + script )
