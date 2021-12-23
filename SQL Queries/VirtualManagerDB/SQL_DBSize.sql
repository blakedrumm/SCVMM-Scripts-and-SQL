SELECT convert(decimal(12,0),round(sf.size/128.000,2)) AS 'FileSize(MB)', 
convert(decimal(12,0),round(fileproperty(sf.name,'SpaceUsed')/128.000,2)) AS 'SpaceUsed(MB)', 
convert(decimal(12,0),round((sf.size-fileproperty(sf.name,'SpaceUsed'))/128.000,2)) AS 'FreeSpace(MB)', 
convert(decimal(12,0),round(sf.maxsize/128.000,2)) AS 'AutoGrowthMB(MAX)',
left(sf.NAME,15) AS 'NAME', 
left(sf.FILENAME,120) AS 'PATH',
sf.FILEID
from dbo.sysfiles sf WITH (NOLOCK)
